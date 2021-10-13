import 'package:nova_system/util/const.dart';
import 'package:nova_system/util/data.dart';
import 'package:nova_system/widgets/wallet.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

Future<Album> fetchAlbum() async {
  final response = await http.get(Uri.parse(
      'https://api.nomics.com/v1/exchange-rates/history?key=${Constants.nomicsKey}&currency=BTC&start=2021-01-01T00%3A00%3A00Z'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Album.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class Album {
  final List<PointModel> chartData;

  Album({
    required this.chartData,
  });

  factory Album.fromJson(List<dynamic> json) {
    List<PointModel> returnData = [];

    for (var i = 0; i < json.length; i++) {
      returnData
          .add(PointModel(pointX: i, pointY: double.parse(json[i]["rate"])));
    }

    return Album(
      chartData: returnData,
    );
  }
}

class Wallets extends StatefulWidget {
  const Wallets({Key? key}) : super(key: key);

  @override
  _WalletsState createState() => _WalletsState();
}

class _WalletsState extends State<Wallets> {
  var colorList = (Constants.matColors.toList()..shuffle());
  late Future<Album> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        child: ListView.builder(
          cacheExtent: 20,
          physics: const NeverScrollableScrollPhysics(),
          primary: false,
          itemCount: coins.length,
          itemBuilder: (BuildContext context, int index) {
            Map coin = coins[index];
            var color = colorList[index % Constants.matColors.length];

            return FutureBuilder<Album>(
              future: futureAlbum,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Wallet(
                      name: coin['name'],
                      icon: coin['icon'],
                      rate: coin['rate'],
                      color: color[0],
                      alt: coin['alt'],
                      colorHex: color[1],
                      data: snapshot.data!.chartData);
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                // By default, show a loading spinner.
                return const SizedBox(
                  width: 20.0,
                  height: 225.0,
                  child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(10),
                        ),
                      ),
                      child: SizedBox(
                        height: 25.0,
                        width: 25.0,
                        child: Align(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(),
                        ),
                      )
                  ),
                );
              },
            );
          },
        ),
        onRefresh: () {
          return Future.delayed(const Duration(seconds: 0), () {
            setState(() {
              Config.chartRefresh();
            });
          });
        },
      ),
    );
  }
}
