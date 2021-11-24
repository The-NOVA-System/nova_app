import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:nova/util/const.dart';
import 'package:nova/widgets/wallet.dart';
import 'package:flutter/material.dart';
import 'package:nova/screens/home.dart';
import 'dart:async';
import 'dart:convert';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';

int length = 100;
int counter = 1;
double page = 1.0;
late IDS idList;
bool locked = false;

Future<List> fetchCharts(pageInternal, idArray, apiKey) async {
  late Response cryptoResponse;
  late Response chartResponse;
  bool decodeError = false;

  cryptoResponse = await client.post(Uri.parse(
      'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&status=active&per-page=$length&page=$pageInternal&ids=${idArray.join(',')}'));

  try {
    var idData = jsonDecode(cryptoResponse.body);
    idList = IDS.fromJson(await idData);

    chartResponse = await client.post(Uri.parse(
        'https://api.nomics.com/v1/currencies/sparkline?key=$apiKey&ids=${idList.idList.take(length).join(",")}&start=${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 365))) + "T00%3A00%3A00Z"}'));
  } catch(error) {
    chartResponse = cryptoResponse;
    decodeError = true;
  }

  if (chartResponse.statusCode == 200 && decodeError == false) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
        return [
      Charts.fromJson(jsonDecode(chartResponse.body)),
      jsonDecode(cryptoResponse.body)
    ];
  } else if (chartResponse.statusCode == 429 || decodeError == true) {
    decodeError = false;
    cryptoResponse = await Future.delayed(const Duration(seconds: 1), () async {
      return await client.post(Uri.parse(
          'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&status=active&per-page=$length&page=$pageInternal&ids=${idArray.join(',')}'));
    });

    try {
      var idData = jsonDecode(cryptoResponse.body);
      idList = IDS.fromJson(await idData);
      chartResponse = await Future.delayed(const Duration(seconds: 1), () async {
        return await client.post(Uri.parse(
            'https://api.nomics.com/v1/currencies/sparkline?key=$apiKey&ids=${idList.idList.take(length).join(",")}&start=${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 365))) + "T00%3A00%3A00Z"}'));
      });
    } catch(error) {
      chartResponse = cryptoResponse;
      decodeError = true;
    }

    if (chartResponse.statusCode == 200 && decodeError == false) {
      return [
        Charts.fromJson(jsonDecode(chartResponse.body)),
        jsonDecode(cryptoResponse.body)
      ];
    } else if (chartResponse.statusCode == 429 || decodeError == true) {
      throw Exception(
          "woah woah woah, slow down! the api we use only allows 1 request per second (cause we're on the free plan). reload again, just a bit slower :)");
    } else {
      throw Exception(
          'Failed to load charts with ${chartResponse.statusCode}: ${chartResponse.body}');
    }
  } else {
    throw Exception(
        'Failed to load charts with ${chartResponse.statusCode}: ${chartResponse.body}');
  }
}

class Charts {
  final List chartData;

  Charts({
    required this.chartData,
  });

  factory Charts.fromJson(List<dynamic> json) {
    List returnData = [];
    List<PointModel> chartData = [];

    for (var x = 0; x < json.length; x++) {
      for (var i = 0; i < json.length; i++) {
        if (json[i]["currency"] == idList.idList[x]) {
          for (var y = 0; y < json[i]["prices"].length; y++) {
            chartData.add(PointModel(
                pointX: y, pointY: double.parse(json[i]["prices"][y])));
          }
          returnData.add(chartData);
          chartData = [];
        }
      }
    }
    return Charts(
      chartData: returnData,
    );
  }
}

class IDS {
  List idList;

  IDS({
    required this.idList,
  });

  factory IDS.fromJson(List<dynamic> json) {
    List returnData = [];

    for (var i = 0; i < json.length; i++) {
      returnData.add(json[i]["id"]);
    }

    return IDS(
      idList: returnData,
    );
  }
}

class Wallets extends StatefulWidget {
  final Function() notifyParent;
  final String nomicsApi;
  const Wallets({Key? key,
    required this.notifyParent,
    required this.nomicsApi,
  }) : super(key: key);

  @override
  _WalletsState createState() => _WalletsState();
}

class _WalletsState extends State<Wallets> {
  var colorList = (Constants.matColors.toList()..shuffle());
  late Future<List> futureCharts;
  late List<dynamic> aggregateList;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  var fireStoreUserRef = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid);

  @override
  void initState() {
    super.initState();
    page = 1.0;
    counter = 1;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: users.doc(FirebaseAuth.instance.currentUser!.uid).get(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Text("Something went wrong");
        }

        if (snapshot.hasData && !snapshot.data!.exists) {
          return const Text("Document does not exist");
        }

        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;

          if (data['assets'].length == 0) {
            return const Scaffold(
              body: Center(child: Text("You have no assets yet!")),
            );
          } else {
            futureCharts = fetchCharts(1, data['assets'], widget.nomicsApi);
            return Scaffold(
              body: LazyLoadScrollView(
                onEndOfPage: () async {
                  page++;
                  List localCharts = [];
                  try {
                    localCharts =
                        await fetchCharts(page.round(), data['assets'], widget.nomicsApi);
                  } catch (err) {
                    localCharts = await Future.delayed(
                        const Duration(seconds: 1), () async {
                      return await fetchCharts(page.round(), data['assets'], widget.nomicsApi);
                    });
                  }
                  aggregateList[1] += localCharts[1];
                  var chartData = [
                    Charts(
                        chartData: aggregateList[0].chartData +
                            localCharts[0].chartData),
                    aggregateList[1]
                  ];
                  setState(() {
                    futureCharts =
                        Future.delayed(const Duration(seconds: 0), () {
                      return chartData;
                    });
                    counter++;
                  });
                },
                scrollOffset: 5625,
                child: RefreshIndicator(
                  child: ListView.builder(
                      shrinkWrap: true,
                      cacheExtent: 9999,
                      physics: const AlwaysScrollableScrollPhysics(),
                      primary: false,
                      itemCount: data['assets'].length,
                      itemBuilder: (BuildContext context, int index) {
                        var color =
                            colorList[index % Constants.matColors.length];
                        if (index == length * counter - 1) {
                          return const SizedBox(
                            width: 20.0,
                            height: 240.0,
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
                                )),
                          );
                        } else {
                          return FutureBuilder<List>(
                            future: futureCharts,
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                aggregateList = snapshot.data!;
                                return Wallet(
                                  notifyParent: widget.notifyParent,
                                  name: snapshot.data![1][index]["name"],
                                  icon:
                                      "https://corsproxy.garvshah.workers.dev/?" +
                                          snapshot.data![1][index]["logo_url"],
                                  rate: data[snapshot.data![1][index]["id"]]
                                      .toString(),
                                  day: double.parse(snapshot.data![1][index]
                                      ["1d"]["price_change_pct"]),
                                  week: double.parse(snapshot.data![1][index]
                                      ["7d"]["price_change_pct"]),
                                  month: double.parse(snapshot.data![1][index]
                                      ["30d"]["price_change_pct"]),
                                  year: double.parse(snapshot.data![1][index]
                                      ["365d"]["price_change_pct"]),
                                  ytd: double.parse(snapshot.data![1][index]
                                      ["ytd"]["price_change_pct"]),
                                  color: color[0],
                                  alt: snapshot.data![1][index]["id"],
                                  colorHex: color[1],
                                  altRate: snapshot.data![1][index]["price"],
                                  data: snapshot.data![0].chartData[index],
                                  buy: false,
                                  index: index,
                                );
                              } else if (snapshot.hasError) {
                                print(snapshot.error?.toString());
                                return SizedBox(
                                  width: 20.0,
                                  height: 240.0,
                                  child: Card(
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(10),
                                        ),
                                      ),
                                      child: SizedBox(
                                        height: 25.0,
                                        width: 25.0,
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Text(
                                                '${snapshot.error}',
                                                textAlign: TextAlign.center,
                                              )),
                                        ),
                                      )),
                                );
                              }

                              // By default, show a loading spinner.
                              return const SizedBox(
                                width: 20.0,
                                height: 240.0,
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
                                    )),
                              );
                            },
                          );
                        }
                      }),
                  onRefresh: () {
                    return Future.delayed(const Duration(seconds: 0), () async {
                      var chartData = await fetchCharts(1, data['assets'], widget.nomicsApi);
                      setState(() {
                        futureCharts =
                            Future.delayed(const Duration(seconds: 0), () {
                          return chartData;
                        });
                        Config.chartRefresh();
                      });
                    });
                  },
                ),
              ),
            );
          }
        }

        return const SizedBox(
          width: 20.0,
          height: 240.0,
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
              )),
        );
      },
    );
  }
}
