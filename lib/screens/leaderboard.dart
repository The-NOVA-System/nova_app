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
  late List<dynamic> leaderName;
  late List<dynamic> leaderValue;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: users.get(),
      builder: (BuildContext context,
          AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          throw Exception("Something went wrong");
        }

        if (snapshot.connectionState ==
            ConnectionState.done) {
          leaderName = List.filled(10000000, null, growable: true);
          leaderValue = List.filled(10000000, null, growable: true);
          //print("leaderName is $leaderName");
          for (var value in snapshot.data!.docs) {
            leaderValue[int.parse(value['USD'].toStringAsFixed(0))] = value['USD'].toStringAsFixed(2);
            leaderName[int.parse(value['USD'].toStringAsFixed(0))] = value['email'].split("@")[0];
          }
          leaderName.removeWhere((value) => value == null);
          leaderValue.removeWhere((value) => value == null);
          leaderName = List.from(leaderName.reversed);
          leaderValue = List.from(leaderValue.reversed);

          print(leaderName);
          print(leaderValue);

          return ListView.builder(
            cacheExtent: 999,
            physics: const AlwaysScrollableScrollPhysics(),
            primary: false,
            shrinkWrap: true,
            itemCount: leaderName.length,
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
                        'https://avatars.dicebear.com/api/avataaars/${leaderName[index]}.svg',
                        width: 50,
                        height: 50,
                        semanticsLabel: 'profile picture',
                        placeholderBuilder: (BuildContext context) => Container(
                            padding: const EdgeInsets.all(30.0),
                            child: const CircularProgressIndicator()),
                      )),
                  title: Text(leaderName[index]),
                  subtitle: Text(leaderValue[index]),
                  trailing: Text('${index + 1}',
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
