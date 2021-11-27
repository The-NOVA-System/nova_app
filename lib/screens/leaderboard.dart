import 'dart:math';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home.dart';
import 'package:nova/screens/user_view.dart';

firebase_storage.FirebaseStorage storage =
    firebase_storage.FirebaseStorage.instance;

Map<String, List> badges = {};
Map userInfo = {};
late ListResult badgesList;
Map<String, String> customProfiles = {};

Future<List> fetchLeader(apiKey) async {
  badgesList = await storage.ref('badges').list();
  for (var value in badgesList.items) {
    badges[value.fullPath.split('.')[0].split('/')[1]] = [await storage.ref(value.fullPath).getDownloadURL(), value.fullPath.split('.')[1]];
  }
  
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference global = FirebaseFirestore.instance.collection('global');
  var userGet = await users.get();
  var badgeGet = await global.doc('badges').get();
  var assetList = [];

  for (var value in userGet.docs) {
    if (value['defaultProfile'] == false) {
      customProfiles[value['email'].split('@')[0]] = await storage.ref(
          'profiles/${value.id}/profile.${value['profileType'].split('/')[1]}')
          .getDownloadURL();
    }
    for (var asset in value['assets']) {
      assetList.add(asset);
      assetList = assetList.toSet().toList();
    }
  }

  var cryptoResponse = await client.post(Uri.parse(
      'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&status=active&ids=${assetList.join(',')}'));


  List<dynamic> cryptoFinal;
  final _random = Random();
  int next(int min, int max) => min + _random.nextInt(max - min);

  if (cryptoResponse.statusCode == 429) {
    cryptoResponse = await Future.delayed(const Duration(seconds: 1), () async {
      return await client.post(Uri.parse(
          'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&status=active&ids=${assetList.join(',')}'));
    });

    if (cryptoResponse.statusCode == 429) {
      cryptoResponse = await Future.delayed(const Duration(seconds: 2), () async {
        return await client.post(Uri.parse(
            'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&status=active&ids=${assetList.join(',')}'));
      });

      if (cryptoResponse.statusCode == 429) {
        cryptoResponse = await Future.delayed(Duration(seconds: next(1, 5)), () async {
          return await client.post(Uri.parse(
              'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&status=active'));
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
  const leaderboard({Key? key, required this.nomicsApi, required this.notifyParent}) : super(key: key);

  @override
  _leaderboardState createState() => _leaderboardState();
}

class _leaderboardState extends State<leaderboard> {
  List<dynamic> leaderList = [];
  Map<String, Widget> profileList = {};
  Map<String, Widget> profileListBig = {};
  double profileListBigSize = 100.0;

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
            leaderList.add([money + value['USD'], value['email'].split("@")[0], value['badges']]);
            if (value['defaultProfile'] == true) {
              profileList[value['email'].split("@")[0]] = ClipOval(
                  child: SvgPicture.network(
                    'https://avatars.dicebear.com/api/avataaars/${value['email']
                        .split("@")[0]}.svg',
                    width: 50,
                    height: 50,
                    semanticsLabel: 'profile picture',
                    placeholderBuilder: (BuildContext context) =>
                    const SizedBox(
                        height: 50,
                        width: 50,
                        child: CircularProgressIndicator()),
                  ));
              profileListBig[value['email'].split("@")[0]] = ClipOval(
                  child: SvgPicture.network(
                    'https://avatars.dicebear.com/api/avataaars/${value['email']
                        .split("@")[0]}.svg',
                    width: profileListBigSize,
                    height: profileListBigSize,
                    semanticsLabel: 'profile picture',
                    placeholderBuilder: (BuildContext context) =>
                    SizedBox(
                        height: profileListBigSize,
                        width: profileListBigSize,
                        child: const CircularProgressIndicator()),
                  ));
            } else {
              profileList[value['email'].split("@")[0]] = ClipOval(
                child: CachedNetworkImage(
                  imageUrl: customProfiles[value['email'].split("@")[0]]!,
                  fit: BoxFit.fill,
                  width: 50,
                  height: 50,
                  placeholder: (context, url) =>
                  const SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                  const SizedBox(
                      height: 50,
                      width: 50,
                      child: Icon(Icons.error)),
                ),
              );
              profileListBig[value['email'].split("@")[0]] = ClipOval(
                child: CachedNetworkImage(
                  imageUrl: customProfiles[value['email'].split("@")[0]]!,
                  fit: BoxFit.fill,
                  width: profileListBigSize,
                  height: profileListBigSize,
                  placeholder: (context, url) =>
                  SizedBox(
                      height: profileListBigSize,
                      width: profileListBigSize,
                      child: const CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                  SizedBox(
                      height: profileListBigSize,
                      width: profileListBigSize,
                      child: const Icon(Icons.error)),
                ),
              );
            }
          }
          leaderList.sort((b, a) => a[0].compareTo(b[0]));

          return ListView.builder(
            cacheExtent: 999,
            physics: const AlwaysScrollableScrollPhysics(),
            primary: false,
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
                      UserProfileRoute(builder: (_) => UserWallets(
                        profile: profileListBig[leaderList[index][1]]!,
                        userData: userInfo[leaderList[index][1]],
                        notifyParent: widget.notifyParent,
                        nomicsApi: widget.nomicsApi,
                      ))
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10),
                    ),
                  ),
                  child: ListTile(
                    leading: Hero(
                      tag: leaderList[index][1],
                        child: profileList[leaderList[index][1]]!
                    ),
                    title: Hero(
                        tag: leaderList[index][1] + " name",
                        child: Material(
                          color: Colors.transparent,
                            child: Text(leaderList[index][1],
                              style: TextStyle(
                                fontSize: 20.0,
                              ),)
                        )
                    ),
                    subtitle: Text("\$${leaderList[index][0].toStringAsFixed(2)} USD"),
                    trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: badges.entries.map((entry) {
                            if (leaderList[index][2].contains(entry.key)) {
                              if (entry.value[1] == "svg") {
                                return Row(
                                    children: [
                                      Tooltip(
                                        message: snapshot.data![2][entry.key],
                                        child: SvgPicture.network(
                                          entry.value[0],
                                          fit: BoxFit.fill,
                                          width: 40,
                                          height: 40,
                                          semanticsLabel: '${entry.key} badge',
                                          placeholderBuilder: (BuildContext context) =>
                                          const SizedBox(
                                              height: 40,
                                              width: 40,
                                              child: CircularProgressIndicator()),
                                        ),
                                      ),
                                      const SizedBox(width: 10)
                                    ],
                                  );
                              } else {
                                return Row(
                                  children: [
                                    Tooltip(
                                      message: snapshot.data![2][entry.key],
                                      child: CachedNetworkImage(
                                        imageUrl: entry.value[0],
                                        fit: BoxFit.fill,
                                        width: 40,
                                        height: 40,
                                        placeholder: (context, url) =>
                                        const SizedBox(
                                            height: 40,
                                            width: 40,
                                            child: CircularProgressIndicator()),
                                        errorWidget: (context, url, error) =>
                                        const SizedBox(
                                            height: 40,
                                            width: 40,
                                            child: Icon(Icons.error)),
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
                ),
              );
            },
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
