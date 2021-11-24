import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:nova/util/const.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'home.dart';

firebase_storage.FirebaseStorage storage =
    firebase_storage.FirebaseStorage.instance;

Map<String, List> badges = {};
late ListResult storageList;

Future<List> fetchLeader(apiKey) async {
  storageList = await storage.ref('badges').list();
  for (var value in storageList.items) {
    badges[value.fullPath.split('.')[0].split('/')[1]] = [await storage.ref(value.fullPath).getDownloadURL(), value.fullPath.split('.')[1]];
  }
  
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference global = FirebaseFirestore.instance.collection('global');
  var userGet = await users.get();
  var badgeGet = await global.doc('badges').get();
  var assetList = [];

  for (var value in userGet.docs) {
    for (var asset in value['assets']) {
      assetList.add(asset);
      assetList = assetList.toSet().toList();
    }
  }

  var cryptoResponse = await client.post(Uri.parse(
      'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&status=active&ids=${assetList.join(',')}'));

  List<dynamic> cryptoFinal;

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

      cryptoFinal = jsonDecode(cryptoResponse.body);
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
  const leaderboard({Key? key, required this.nomicsApi}) : super(key: key);

  @override
  _leaderboardState createState() => _leaderboardState();
}

class _leaderboardState extends State<leaderboard> {
  List<dynamic> leaderList = [];

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
          }
          leaderList.sort((b, a) => a[0].compareTo(b[0]));


          return ListView.builder(
            cacheExtent: 999,
            physics: const AlwaysScrollableScrollPhysics(),
            primary: false,
            shrinkWrap: true,
            itemCount: leaderList.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                elevation: 4,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
                child: ListTile(
                  leading: ClipOval(
                      child: SvgPicture.network(
                    'https://avatars.dicebear.com/api/avataaars/${leaderList[index][1]}.svg',
                    width: 50,
                    height: 50,
                    semanticsLabel: 'profile picture',
                    placeholderBuilder: (BuildContext context) =>
                        const SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator()),
                  )),
                  title: Text(leaderList[index][1]),
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
