import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nova/util/data.dart';
import 'package:flutter/material.dart';

class leaderboard extends StatefulWidget {
  const leaderboard({Key? key}) : super(key: key);

  @override
  _leaderboardState createState() => _leaderboardState();
}

class _leaderboardState extends State<leaderboard> {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  List<dynamic> leaderList = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: users.get(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          throw Exception("Something went wrong");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          //print("leaderName is $leaderName");
          for (var value in snapshot.data!.docs) {
            leaderList.add([value['USD'], value['email'].split("@")[0]]);
          }
          print(leaderList);
          leaderList.sort((b, a) => a[0].compareTo(b[0]));
          print(leaderList);

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
                  trailing: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.bold,
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
