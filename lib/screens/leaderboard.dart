import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home.dart';
import 'package:nova/screens/user_view.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

firebase_storage.FirebaseStorage storage =
    firebase_storage.FirebaseStorage.instance;

Map badges = {};
Map userInfo = {};
late ListResult badgesList;
Map customProfiles = {};
ItemScrollController _scrollController = ItemScrollController();
int userPosition = 0;

Future<List> fetchLeader(apiKey) async {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference global = FirebaseFirestore.instance.collection('global');

  var badgeURLGet = await global.doc('badge-urls').get();

  badges = badgeURLGet.data()! as Map;

  badgesList = await storage.ref('badges').list();
  for (var value in badgesList.items) {
    if (badges.containsKey(value.fullPath.split('.')[0].split('/')[1])) {
    } else {
      badges[value.fullPath.split('.')[0].split('/')[1]] = [
        await storage.ref(value.fullPath).getDownloadURL(),
        value.fullPath.split('.')[1]
      ];
    }
  }

  if (badges != badgeURLGet.data()! as Map) {
    global.doc('badge-urls').set(
          badges,
          SetOptions(merge: true),
        );
  }

  var userGet = await users.get();
  var badgeGet = await global.doc('badges').get();
  var cacheURLGet = await global.doc('cached-urls').get();

  var assetList = [];

  customProfiles = cacheURLGet.data()! as Map;

  for (var value in userGet.docs) {
    if (value['defaultProfile'] == false) {
      if (customProfiles.containsKey(value['email'].split('@')[0])) {
      } else {
        customProfiles[value['email'].split('@')[0]] = await storage
            .ref(
                'profiles/${value.id}/profile.${value['profileType'].split('/')[1]}')
            .getDownloadURL();
      }
    }
    assetList.addAll(value['assets']);
    assetList = assetList.toSet().toList();
  }

  if (customProfiles != cacheURLGet.data()! as Map) {
    global.doc('cached-urls').set(
          customProfiles,
          SetOptions(merge: true),
        );
  }

  var cryptoResponse = await client.post(Uri.parse(
      'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&per-page=1000000&ids=${assetList.join(',')}'));

  List<dynamic> cryptoFinal;
  final _random = Random();
  int next(int min, int max) => min + _random.nextInt(max - min);

  if (cryptoResponse.statusCode == 429) {
    cryptoResponse = await Future.delayed(const Duration(seconds: 1), () async {
      return await client.post(Uri.parse(
          'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&per-page=1000000&ids=${assetList.join(',')}'));
    });

    if (cryptoResponse.statusCode == 429) {
      cryptoResponse =
          await Future.delayed(const Duration(seconds: 2), () async {
        return await client.post(Uri.parse(
            'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&per-page=1000000&ids=${assetList.join(',')}'));
      });

      if (cryptoResponse.statusCode == 429) {
        cryptoResponse =
            await Future.delayed(Duration(seconds: next(1, 5)), () async {
          return await client.post(Uri.parse(
              'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&per-page=1000000'));
        });

        cryptoFinal = jsonDecode(cryptoResponse.body);
      } else {
        cryptoFinal = jsonDecode(cryptoResponse.body);
      }
    } else {
      cryptoFinal = jsonDecode(cryptoResponse.body);
    }
  } else {
    cryptoFinal = jsonDecode(cryptoResponse.body);
  }

  return [userGet, cryptoFinal, badgeGet];
}

class leaderboard extends StatefulWidget {
  final String nomicsApi;
  final Function() notifyParent;
  const leaderboard(
      {Key? key, required this.nomicsApi, required this.notifyParent})
      : super(key: key);

  @override
  _leaderboardState createState() => _leaderboardState();
}

class _leaderboardState extends State<leaderboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hideAnimation;
  List<dynamic> leaderList = [];
  Map<String, Widget> profileList = {};

  @override
  initState() {
    super.initState();
    _hideAnimation =
        AnimationController(duration: kThemeAnimationDuration, vsync: this);
    _hideAnimation.forward();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth == 0) {
      if (notification is UserScrollNotification) {
        final UserScrollNotification userScroll = notification;
        switch (userScroll.direction) {
          case ScrollDirection.forward:
            if (userScroll.metrics.maxScrollExtent !=
                userScroll.metrics.minScrollExtent) {
              _hideAnimation.forward();
            }
            break;
          case ScrollDirection.reverse:
            if (userScroll.metrics.maxScrollExtent !=
                userScroll.metrics.minScrollExtent) {
              _hideAnimation.reverse();
            }
            break;
          case ScrollDirection.idle:
            break;
        }
      }
    }
    return false;
  }

  @override
  void dispose() {
    _hideAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: fetchLeader(widget.nomicsApi),
      builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Something went wrong: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.done) {
          for (var value in snapshot.data![0].docs) {
            /*CollectionReference users = FirebaseFirestore.instance.collection('users');

            users.doc(value.id).set({
              'superNova': false,
            },
              SetOptions(merge: true),);*/

            userInfo[value['email'].split("@")[0]] = value.data();

            num money = 0;
            for (var alt in value['assets']) {
              for (var i = 0; i < snapshot.data![1].length; i++) {
                if (snapshot.data![1][i]['id'] == alt) {
                  money += (double.parse(snapshot.data![1][i]['price']) *
                      value[snapshot.data![1][i]['id']]);
                }
              }
            }
            leaderList.add([
              money + value['USD'],
              value['email'].split("@")[0],
              value['badges'],
              value['username'],
              value.id
            ]);

            if (value['defaultProfile'] == true) {
              profileList[value['email'].split("@")[0]] = ClipOval(
                  child: AspectRatio(
                aspectRatio: 1.0,
                child: SvgPicture.network(
                  'https://avatars.dicebear.com/api/avataaars/${value['email'].split("@")[0]}.svg',
                  width: 50,
                  height: 50,
                  semanticsLabel: 'profile picture',
                  placeholderBuilder: (BuildContext context) => const SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator()),
                ),
              ));
            } else {
              profileList[value['email'].split("@")[0]] = AspectRatio(
                aspectRatio: 1.0,
                child: CachedNetworkImage(
                  imageUrl: customProfiles[value['email'].split("@")[0]]!,
                  fit: BoxFit.fill,
                  width: 50,
                  height: 50,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 25,
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => const SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const SizedBox(
                      height: 50, width: 50, child: Icon(Icons.error)),
                ),
              );
            }
          }
          leaderList.sort((b, a) => a[0].compareTo(b[0]));

          userPosition = leaderList.indexOf(leaderList
              .where((e) =>
                  e[1] ==
                  FirebaseAuth.instance.currentUser!.email!.split("@")[0])
              .first);

          return NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: Scaffold(
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
              floatingActionButton: ScaleTransition(
                scale: _hideAnimation,
                child: FloatingActionButton.extended(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  onPressed: () {
                    _scrollController.scrollTo(
                        index: userPosition,
                        duration: const Duration(seconds: 1),
                        alignment: 0.35,
                        curve: Curves.easeOutCubic);
                  },
                  label: const Text('Show My Position'),
                ),
              ),
              body: ScrollablePositionedList.builder(
                itemScrollController: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: leaderList.length,
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    customBorder: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (c, a1, a2) => UserWallets(
                            worth:
                                "\$${leaderList[index][0].toStringAsFixed(2)} USD",
                            profile: profileList[leaderList[index][1]]!,
                            userData: userInfo[leaderList[index][1]],
                            notifyParent: widget.notifyParent,
                            nomicsApi: widget.nomicsApi,
                            badgesColumn: Row(
                              children: badges.entries.map((entry) {
                                if (leaderList[index][2].contains(entry.key)) {
                                  if (entry.value[1] == "svg") {
                                    return Row(
                                      children: [
                                        Hero(
                                          tag:
                                              "${leaderList[index][1]}'s ${entry.key} badge",
                                          child: Tooltip(
                                            message: snapshot.data![2]
                                                [entry.key],
                                            child: SvgPicture.network(
                                              entry.value[0],
                                              fit: BoxFit.fill,
                                              width: 40,
                                              height: 40,
                                              semanticsLabel:
                                                  '${entry.key} badge',
                                              placeholderBuilder: (BuildContext
                                                      context) =>
                                                  const SizedBox(
                                                      height: 40,
                                                      width: 40,
                                                      child:
                                                          CircularProgressIndicator()),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10)
                                      ],
                                    );
                                  } else {
                                    return Row(
                                      children: [
                                        Hero(
                                          tag:
                                              "${leaderList[index][1]}'s ${entry.key} badge",
                                          child: Tooltip(
                                            message: snapshot.data![2]
                                                [entry.key],
                                            child: CachedNetworkImage(
                                              imageUrl: entry.value[0],
                                              fit: BoxFit.fill,
                                              width: 40,
                                              height: 40,
                                              placeholder: (context, url) =>
                                                  const SizedBox(
                                                      height: 40,
                                                      width: 40,
                                                      child:
                                                          CircularProgressIndicator()),
                                              errorWidget: (context, url,
                                                      error) =>
                                                  const SizedBox(
                                                      height: 40,
                                                      width: 40,
                                                      child: Icon(Icons.error)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10)
                                      ],
                                    );
                                  }
                                } else {
                                  return const Text("");
                                }
                              }).toList(),
                            ),
                          ),
                          transitionsBuilder: (c, anim, a2, child) =>
                              FadeTransition(opacity: anim, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 1500),
                          reverseTransitionDuration: const Duration(milliseconds: 650),
                        ),
                      );
                    },
                    child: (() {
                      if (FirebaseAuth.instance.currentUser!.email!
                              .split("@")[0] ==
                          leaderList[index][1]) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 8.0),
                          child: ListTile(
                            leading: Hero(
                                tag: leaderList[index][1],
                                child: profileList[leaderList[index][1]]!),
                            title: Hero(
                                tag: leaderList[index][1] + " name",
                                child: Material(
                                    color: Colors.transparent,
                                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance.collection("global").doc("badges").snapshots().asBroadcastStream(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                                        if (snapshot.hasError) {
                                          return const Text("Something went wrong");
                                        }

                                        if (snapshot.connectionState ==
                                            ConnectionState.active) {

                                          return Text(
                                            leaderList[index][3],
                                            style: const TextStyle(
                                              fontSize: 18.0,
                                            ),
                                          );
                                        }

                                        return Text(
                                          leaderList[index][3],
                                          style: const TextStyle(
                                            fontSize: 18.0,
                                          ),
                                        );
                                      },
                                    ))),
                            subtitle: Hero(
                                tag: leaderList[index][1] + " worth",
                                child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                        "\$${leaderList[index][0].toStringAsFixed(2)} USD"))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: badges.entries.map((entry) {
                                    if (leaderList[index][2]
                                        .contains(entry.key)) {
                                      if (entry.value[1] == "svg") {
                                        return Row(
                                          children: [
                                            Hero(
                                              tag:
                                                  "${leaderList[index][1]}'s ${entry.key} badge",
                                              child: Tooltip(
                                                message: snapshot.data![2]
                                                    [entry.key],
                                                child: SvgPicture.network(
                                                  entry.value[0],
                                                  fit: BoxFit.fill,
                                                  width: 40,
                                                  height: 40,
                                                  semanticsLabel:
                                                      '${entry.key} badge',
                                                  placeholderBuilder: (BuildContext
                                                          context) =>
                                                      const SizedBox(
                                                          height: 40,
                                                          width: 40,
                                                          child:
                                                              CircularProgressIndicator()),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10)
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          children: [
                                            Hero(
                                              tag:
                                                  "${leaderList[index][1]}'s ${entry.key} badge",
                                              child: Tooltip(
                                                message: snapshot.data![2]
                                                    [entry.key],
                                                child: CachedNetworkImage(
                                                  imageUrl: entry.value[0],
                                                  fit: BoxFit.fill,
                                                  width: 40,
                                                  height: 40,
                                                  placeholder: (context, url) =>
                                                      const SizedBox(
                                                          height: 40,
                                                          width: 40,
                                                          child:
                                                              CircularProgressIndicator()),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const SizedBox(
                                                              height: 40,
                                                              width: 40,
                                                              child: Icon(
                                                                  Icons.error)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10)
                                          ],
                                        );
                                      }
                                    } else {
                                      return const Text("");
                                    }
                                  }).toList(),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).disabledColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Card(
                          elevation: 4,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: ListTile(
                            leading: Hero(
                                tag: leaderList[index][1],
                                child: profileList[leaderList[index][1]]!),
                            title: Hero(
                                tag: leaderList[index][1] + " name",
                                child: Material(
                                    color: Colors.transparent,
                                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                      stream: FirebaseFirestore.instance.collection("global").doc("badges").snapshots().asBroadcastStream(),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                                        if (snapshot.hasError) {
                                          return const Text("Something went wrong");
                                        }

                                        if (snapshot.connectionState ==
                                            ConnectionState.active) {

                                          return Text(
                                            leaderList[index][3],
                                            style: const TextStyle(
                                              fontSize: 18.0,
                                            ),
                                          );
                                        }

                                        return Text(
                                          leaderList[index][3],
                                          style: const TextStyle(
                                            fontSize: 18.0,
                                          ),
                                        );
                                      },
                                    ))),
                            subtitle: Hero(
                                tag: leaderList[index][1] + " worth",
                                child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                        "\$${leaderList[index][0].toStringAsFixed(2)} USD"))),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: badges.entries.map((entry) {
                                    if (leaderList[index][2]
                                        .contains(entry.key)) {
                                      if (entry.value[1] == "svg") {
                                        return Row(
                                          children: [
                                            Hero(
                                              tag:
                                                  "${leaderList[index][1]}'s ${entry.key} badge",
                                              child: Tooltip(
                                                message: snapshot.data![2]
                                                    [entry.key],
                                                child: SvgPicture.network(
                                                  entry.value[0],
                                                  fit: BoxFit.fill,
                                                  width: 40,
                                                  height: 40,
                                                  semanticsLabel:
                                                      '${entry.key} badge',
                                                  placeholderBuilder: (BuildContext
                                                          context) =>
                                                      const SizedBox(
                                                          height: 40,
                                                          width: 40,
                                                          child:
                                                              CircularProgressIndicator()),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10)
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          children: [
                                            Hero(
                                              tag:
                                                  "${leaderList[index][1]}'s ${entry.key} badge",
                                              child: Tooltip(
                                                message: snapshot.data![2]
                                                    [entry.key],
                                                child: CachedNetworkImage(
                                                  imageUrl: entry.value[0],
                                                  fit: BoxFit.fill,
                                                  width: 40,
                                                  height: 40,
                                                  placeholder: (context, url) =>
                                                      const SizedBox(
                                                          height: 40,
                                                          width: 40,
                                                          child:
                                                              CircularProgressIndicator()),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const SizedBox(
                                                              height: 40,
                                                              width: 40,
                                                              child: Icon(
                                                                  Icons.error)),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10)
                                          ],
                                        );
                                      }
                                    } else {
                                      return const Text("");
                                    }
                                  }).toList(),
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Theme.of(context).disabledColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    }()),
                  );
                },
              ),
            ),
          );
        }

        return const SizedBox(
          height: 25.0,
          width: 25.0,
          child: Align(
            alignment: Alignment.center,
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class UserProfileRoute extends MaterialPageRoute {
  UserProfileRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Duration get transitionDuration => const Duration(seconds: 1);
}
