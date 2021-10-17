import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:nova_system/util/const.dart';
import 'package:nova_system/widgets/wallet.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

int length = 10;
double page = 1.0;
late IDS idList;

Future<List> fetchCharts() async {
  late Response cryptoResponse;
  late Response chartResponse;

  var client = http.Client();
  try {
    cryptoResponse = await client.post(Uri.parse(
        'https://api.nomics.com/v1/currencies/ticker?key=${Constants.nomicsKey}&status=active&per-page=$length&page=${page.round()}&interval=7d'));

    idList = IDS.fromJson(jsonDecode(cryptoResponse.body));

    chartResponse = await client.post(Uri.parse(
        'https://api.nomics.com/v1/currencies/sparkline?key=${Constants.nomicsKey}&ids=${idList.idList.take(length).join(",")}&start=${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 365)))+"T00%3A00%3A00Z"}'));

  } finally {
    client.close();
  }
  if (chartResponse.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return [Charts.fromJson(jsonDecode(chartResponse.body)), jsonDecode(cryptoResponse.body)];
  } else if (chartResponse.statusCode == 429) {
    throw Exception("woah woah woah, slow down! the api we use only allows 1 request per second (cause we're on the free plan). reload again, just a bit slower :)");
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load charts with ${chartResponse.statusCode}: ${chartResponse.body}');
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
            chartData
                .add(PointModel(
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
  const Wallets({Key? key}) : super(key: key);

  @override
  _WalletsState createState() => _WalletsState();
}

class _WalletsState extends State<Wallets> {
  var colorList = (Constants.matColors.toList()..shuffle());
  late Future<List> futureCharts;

  @override
  void initState() {
    super.initState();
    futureCharts = fetchCharts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        child: ListView.builder(
          shrinkWrap: true,
          cacheExtent: 20,
          physics: const NeverScrollableScrollPhysics(),
          primary: false,
          itemCount: length,
          itemBuilder: (BuildContext context, int index) {
            var color = colorList[index % Constants.matColors.length];
            print("page before is $page");
            page = page + 1/length;
            print("page after is $page");

            return FutureBuilder<List>(
              future: futureCharts,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Wallet(
                      name: snapshot.data![1][index]["name"],
                      icon: snapshot.data![1][index]["logo_url"],
                      rate: snapshot.data![1][index]["price"],
                      priceChange: double.parse(snapshot.data![1][index]["7d"]["price_change_pct"]),
                      color: color[0],
                      alt: snapshot.data![1][index]["id"],
                      colorHex: color[1],
                      data: snapshot.data![0].chartData[index]);
                } else if (snapshot.hasError) {
                  return SizedBox(
                    width: 20.0,
                    height: 225.0,
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
                              padding: const EdgeInsets.all(16.0),
                              child: Text('${snapshot.error}', textAlign: TextAlign.center,)
                          ),
                        ),
                      )
                  ),
                  );
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
