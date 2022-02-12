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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:paginated_search_bar/paginated_search_bar.dart';

int length = 100;
int counter = 1;
double page = 1.0;
late IDS idList;

CollectionReference global = FirebaseFirestore.instance.collection('global');

var searchGet = global.doc('search').get();

class ExampleItem {
  final String title;

  ExampleItem({
    required this.title,
  });
}

Future<List> fetchCharts(pageInternal, apiKey, [urlString]) async {
  late Response cryptoResponse;
  late Response chartResponse;
  bool decodeError = false;

  urlString ??=
      'https://api.nomics.com/v1/currencies/ticker?key=$apiKey&per-page=$length&page=$pageInternal';

  cryptoResponse = await client.post(Uri.parse(urlString));

  try {
    var idData = jsonDecode(cryptoResponse.body);
    idList = IDS.fromJson(await idData);

    chartResponse = await client.post(Uri.parse(
        'https://api.nomics.com/v1/currencies/sparkline?key=$apiKey&ids=${idList.idList.take(length).join(",")}&start=${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 365))) + "T00%3A00%3A00Z"}'));
  } catch (error) {
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
      return await client.post(Uri.parse(urlString));
    });

    try {
      var idData = jsonDecode(cryptoResponse.body);
      idList = IDS.fromJson(await idData);
      chartResponse =
          await Future.delayed(const Duration(seconds: 1), () async {
        return await client.post(Uri.parse(
            'https://api.nomics.com/v1/currencies/sparkline?key=$apiKey&ids=${idList.idList.take(length).join(",")}&start=${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 365))) + "T00%3A00%3A00Z"}'));
      });
    } catch (error) {
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

class Search {
  List idList;
  List nameList;
  Map<String, dynamic> map;

  Search({
    required this.idList,
    required this.nameList,
    required this.map,
  });

  factory Search.fromJson(List<dynamic> json) {
    List returnIDList = [];
    List returnNameList = [];
    Map<String, dynamic> returnMap = {};

    for (var i = 0; i < json.length; i++) {
      if (json[i]["name"] != null &&
          json[i]["id"] != null &&
          json[i]["name"] != '' &&
          json[i]["id"] != '') {
        returnIDList.add(json[i]["id"]);
        returnNameList.add(json[i]["name"]);
        if (returnMap[json[i]["name"]] == null) {
          returnMap[json[i]["name"]] = json[i]["id"];
        }
      }
    }

    return Search(
        idList: returnIDList, nameList: returnNameList, map: returnMap);
  }
}

class Buy extends StatefulWidget {
  final Function() notifyParent;
  final String nomicsApi;

  const Buy({Key? key, required this.notifyParent, required this.nomicsApi})
      : super(key: key);

  @override
  _BuyState createState() => _BuyState();
}

class _BuyState extends State<Buy> {
  var colorList = (Constants.matColors.toList()..shuffle());
  late Future<List> futureCharts;
  late List<dynamic> aggregateList;

  @override
  void initState() {
    super.initState();
    page = 1.0;
    counter = 1;
    futureCharts = fetchCharts(1, widget.nomicsApi);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LazyLoadScrollView(
        onEndOfPage: () async {
          page++;
          List localCharts = [];
          try {
            localCharts = await fetchCharts(page.round(), widget.nomicsApi);
          } catch (err) {
            localCharts =
                await Future.delayed(const Duration(seconds: 1), () async {
              return await fetchCharts(page.round(), widget.nomicsApi);
            });
          }
          aggregateList[1] += localCharts[1];
          var chartData = [
            Charts(
                chartData:
                    aggregateList[0].chartData + localCharts[0].chartData),
            aggregateList[1]
          ];
          setState(() {
            futureCharts = Future.delayed(const Duration(seconds: 0), () {
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
              itemCount: length * counter,
              itemBuilder: (BuildContext context, int index) {
                var color = colorList[index % Constants.matColors.length];
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: PaginatedSearchBar<ExampleItem>(
                      containerDecoration: (() {
                        if (Theme.of(context).brightness == Brightness.light) {
                          return null;
                        } else {
                          return BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(8));
                        }
                      }()),
                      hintText: "Search for Cryptocurrencies",
                      onSubmit: (
                          {required ExampleItem? item,
                          required String searchQuery}) async {
                        var searchMap = (await searchGet).data()! as Map;

                        if (searchQuery.split(':')[0] == 'ids') {
                          var idData = fetchCharts(1, widget.nomicsApi,
                              'https://api.nomics.com/v1/currencies/ticker?key=${widget.nomicsApi}&ids=${searchQuery.split(':')[1]}');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => (() {
                                      return Scaffold(
                                        appBar: AppBar(
                                          title:
                                              const Text("Search Results..."),
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          foregroundColor: Theme.of(context)
                                              .appBarTheme
                                              .toolbarTextStyle!
                                              .color,
                                        ),
                                        body: ListView.builder(
                                            shrinkWrap: true,
                                            cacheExtent: 9999,
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            primary: false,
                                            itemCount: searchQuery
                                                .split(':')[1]
                                                .split(",")
                                                .length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              if (kIsWeb) {
                                                return FutureBuilder<List>(
                                                  future: idData,
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      aggregateList =
                                                          snapshot.data!;
                                                      return Wallet(
                                                        buttonActive: true,
                                                        notifyParent:
                                                            widget.notifyParent,
                                                        name: snapshot.data![1]
                                                            [index]["name"],
                                                        icon:
                                                            "https://corsproxy.garvshah.workers.dev/?" +
                                                                snapshot.data![
                                                                            1]
                                                                        [index][
                                                                    "logo_url"],
                                                        rate: snapshot.data![1]
                                                            [index]["price"],
                                                        day: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["1d"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["1d"][
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        week: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["7d"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["7d"][
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        month: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["30d"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["30d"][
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        year: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["365d"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["365d"]
                                                                    [
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        ytd: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["ytd"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["ytd"][
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        color: color[0],
                                                        alt: snapshot.data![1]
                                                            [index]["id"],
                                                        colorHex: color[1],
                                                        data: (() {
                                                          if (snapshot
                                                                  .data![0]
                                                                  .chartData
                                                                  .isEmpty ==
                                                              true) {
                                                            return null;
                                                          } else {
                                                            return snapshot
                                                                    .data![0]
                                                                    .chartData[
                                                                index];
                                                          }
                                                        }()),
                                                        buy: true,
                                                        index: index,
                                                      );
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return SizedBox(
                                                        width: 20.0,
                                                        height: 288.0,
                                                        child: Card(
                                                            shape:
                                                                const RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .all(
                                                                Radius.circular(
                                                                    10),
                                                              ),
                                                            ),
                                                            child: SizedBox(
                                                              height: 25.0,
                                                              width: 25.0,
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Padding(
                                                                    padding: const EdgeInsets
                                                                            .all(
                                                                        16.0),
                                                                    child: Text(
                                                                      '${snapshot.error}',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    )),
                                                              ),
                                                            )),
                                                      );
                                                    }

                                                    // By default, show a loading spinner.
                                                    return const SizedBox(
                                                      width: 20.0,
                                                      height: 288.0,
                                                      child: Card(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  10),
                                                            ),
                                                          ),
                                                          child: SizedBox(
                                                            height: 25.0,
                                                            width: 25.0,
                                                            child: Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          )),
                                                    );
                                                  },
                                                );
                                              } else {
                                                return FutureBuilder<List>(
                                                  future: idData,
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      aggregateList =
                                                          snapshot.data!;
                                                      return Wallet(
                                                        buttonActive: true,
                                                        notifyParent:
                                                            widget.notifyParent,
                                                        name: snapshot.data![1]
                                                            [index]["name"],
                                                        icon: snapshot.data![1]
                                                            [index]["logo_url"],
                                                        rate: snapshot.data![1]
                                                            [index]["price"],
                                                        day: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["1d"][
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        week: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["7d"][
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        month: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["30d"][
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        year: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["365d"]
                                                                    [
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        ytd: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["ytd"][
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        color: color[0],
                                                        alt: snapshot.data![1]
                                                            [index]["id"],
                                                        colorHex: color[1],
                                                        data: (() {
                                                          if (snapshot
                                                                  .data![0]
                                                                  .chartData
                                                                  .isEmpty ==
                                                              true) {
                                                            return null;
                                                          } else {
                                                            return snapshot
                                                                    .data![0]
                                                                    .chartData[
                                                                index];
                                                          }
                                                        }()),
                                                        buy: true,
                                                        index: index,
                                                      );
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return SizedBox(
                                                        width: 20.0,
                                                        height: 288.0,
                                                        child: Card(
                                                            shape:
                                                                const RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .all(
                                                                Radius.circular(
                                                                    10),
                                                              ),
                                                            ),
                                                            child: SizedBox(
                                                              height: 25.0,
                                                              width: 25.0,
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Padding(
                                                                    padding: const EdgeInsets
                                                                            .all(
                                                                        16.0),
                                                                    child: Text(
                                                                      '${snapshot.error}',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    )),
                                                              ),
                                                            )),
                                                      );
                                                    }

                                                    // By default, show a loading spinner.
                                                    return const SizedBox(
                                                      width: 20.0,
                                                      height: 288.0,
                                                      child: Card(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  10),
                                                            ),
                                                          ),
                                                          child: SizedBox(
                                                            height: 25.0,
                                                            width: 25.0,
                                                            child: Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          )),
                                                    );
                                                  },
                                                );
                                              }
                                            }),
                                      );
                                    }())),
                          );
                        } else {
                          List _itemList = searchMap.entries
                              .map((entry) => entry.key)
                              .toList();

                          var itemList = _itemList
                              .where((item) => item
                                  .toLowerCase()
                                  .contains(searchQuery.toLowerCase()))
                              .toList();

                          itemList =
                              itemList.map((item) => searchMap[item]).toList();

                          var idData = fetchCharts(1, widget.nomicsApi,
                              'https://api.nomics.com/v1/currencies/ticker?key=${widget.nomicsApi}&ids=${itemList.take(100).join(",")}');

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => (() {
                                      return Scaffold(
                                        appBar: AppBar(
                                          title:
                                              const Text("Search Results..."),
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          foregroundColor: Theme.of(context)
                                              .appBarTheme
                                              .toolbarTextStyle!
                                              .color,
                                        ),
                                        body: ListView.builder(
                                            shrinkWrap: true,
                                            cacheExtent: 9999,
                                            physics:
                                                const AlwaysScrollableScrollPhysics(),
                                            primary: false,
                                            itemCount: itemList.take(75).length,
                                            itemBuilder: (BuildContext context,
                                                int index) {
                                              if (kIsWeb) {
                                                return FutureBuilder<List>(
                                                  future: idData,
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      aggregateList =
                                                          snapshot.data!;
                                                      return Wallet(
                                                        buttonActive: true,
                                                        notifyParent:
                                                            widget.notifyParent,
                                                        name: snapshot.data![1]
                                                            [index]["name"],
                                                        icon:
                                                            "https://corsproxy.garvshah.workers.dev/?" +
                                                                snapshot.data![
                                                                            1]
                                                                        [index][
                                                                    "logo_url"],
                                                        rate: snapshot.data![1]
                                                            [index]["price"],
                                                        day: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["1d"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["1d"][
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        week: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["7d"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["7d"][
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        month: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["30d"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["30d"][
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        year: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["365d"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["365d"]
                                                                    [
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        ytd: (() {
                                                          if (snapshot.data![1]
                                                                      [index]
                                                                  ["ytd"] ==
                                                              null) {
                                                            return null;
                                                          } else {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["ytd"][
                                                                    "price_change_pct"]);
                                                          }
                                                        }()),
                                                        color: color[0],
                                                        alt: snapshot.data![1]
                                                            [index]["id"],
                                                        colorHex: color[1],
                                                        data: (() {
                                                          if (snapshot
                                                                  .data![0]
                                                                  .chartData
                                                                  .isEmpty ==
                                                              true) {
                                                            return null;
                                                          } else {
                                                            return snapshot
                                                                    .data![0]
                                                                    .chartData[
                                                                index];
                                                          }
                                                        }()),
                                                        buy: true,
                                                        index: index,
                                                      );
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return SizedBox(
                                                        width: 20.0,
                                                        height: 288.0,
                                                        child: Card(
                                                            shape:
                                                                const RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .all(
                                                                Radius.circular(
                                                                    10),
                                                              ),
                                                            ),
                                                            child: SizedBox(
                                                              height: 25.0,
                                                              width: 25.0,
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Padding(
                                                                    padding: const EdgeInsets
                                                                            .all(
                                                                        16.0),
                                                                    child: Text(
                                                                      '${snapshot.error}',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    )),
                                                              ),
                                                            )),
                                                      );
                                                    }

                                                    // By default, show a loading spinner.
                                                    return const SizedBox(
                                                      width: 20.0,
                                                      height: 288.0,
                                                      child: Card(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  10),
                                                            ),
                                                          ),
                                                          child: SizedBox(
                                                            height: 25.0,
                                                            width: 25.0,
                                                            child: Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          )),
                                                    );
                                                  },
                                                );
                                              } else {
                                                return FutureBuilder<List>(
                                                  future: idData,
                                                  builder: (context, snapshot) {
                                                    if (snapshot.hasData) {
                                                      aggregateList =
                                                          snapshot.data!;
                                                      return Wallet(
                                                        buttonActive: true,
                                                        notifyParent:
                                                            widget.notifyParent,
                                                        name: snapshot.data![1]
                                                            [index]["name"],
                                                        icon: snapshot.data![1]
                                                            [index]["logo_url"],
                                                        rate: snapshot.data![1]
                                                            [index]["price"],
                                                        day: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["1d"][
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        week: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["7d"][
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        month: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["30d"][
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        year: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["365d"]
                                                                    [
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        ytd: (() {
                                                          try {
                                                            return double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["ytd"][
                                                                    "price_change_pct"]);
                                                          } catch (err) {
                                                            return 0.0;
                                                          }
                                                        }()),
                                                        color: color[0],
                                                        alt: snapshot.data![1]
                                                            [index]["id"],
                                                        colorHex: color[1],
                                                        data: (() {
                                                          if (snapshot
                                                                  .data![0]
                                                                  .chartData
                                                                  .isEmpty ==
                                                              true) {
                                                            return null;
                                                          } else {
                                                            return snapshot
                                                                    .data![0]
                                                                    .chartData[
                                                                index];
                                                          }
                                                        }()),
                                                        buy: true,
                                                        index: index,
                                                      );
                                                    } else if (snapshot
                                                        .hasError) {
                                                      return SizedBox(
                                                        width: 20.0,
                                                        height: 288.0,
                                                        child: Card(
                                                            shape:
                                                                const RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .all(
                                                                Radius.circular(
                                                                    10),
                                                              ),
                                                            ),
                                                            child: SizedBox(
                                                              height: 25.0,
                                                              width: 25.0,
                                                              child: Align(
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: Padding(
                                                                    padding: const EdgeInsets
                                                                            .all(
                                                                        16.0),
                                                                    child: Text(
                                                                      '${snapshot.error}',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                    )),
                                                              ),
                                                            )),
                                                      );
                                                    }

                                                    // By default, show a loading spinner.
                                                    return const SizedBox(
                                                      width: 20.0,
                                                      height: 288.0,
                                                      child: Card(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .all(
                                                              Radius.circular(
                                                                  10),
                                                            ),
                                                          ),
                                                          child: SizedBox(
                                                            height: 25.0,
                                                            width: 25.0,
                                                            child: Align(
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            ),
                                                          )),
                                                    );
                                                  },
                                                );
                                              }
                                            }),
                                      );
                                    }())),
                          );
                        }
                      },
                      onSearch: ({
                        required pageIndex,
                        required pageSize,
                        required searchQuery,
                      }) async {
                        var searchMap = (await searchGet).data()! as Map;

                        /*var idData = await fetchCharts(1, widget.nomicsApi,
                            'https://api.nomics.com/v1/currencies/ticker?key=${widget.nomicsApi}&status=active');
                        var search = Search.fromJson(idData[1]);

                        Map<String, dynamic> map = search.map;

                        if (searchMap != map) {
                          await global.doc("search").set(
                            map,
                            SetOptions(merge: true),
                          );
                        }*/

                        List _itemList = searchMap.entries
                            .map((entry) => entry.key)
                            .toList();

                        var itemList = _itemList
                            .where((item) => item
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase()))
                            .toList();
                        List<ExampleItem> itemListFinal = [];
                        for (var value in itemList) {
                          itemListFinal.add(ExampleItem(title: value));
                        }
                        return itemListFinal;
                      },
                      itemBuilder: (
                        context, {
                        required item,
                        required index,
                      }) {
                        return InkWell(
                            onTap: () async {
                              var searchMap = (await searchGet).data()! as Map;
                              var searchResponse = fetchCharts(
                                  1,
                                  widget.nomicsApi,
                                  'https://api.nomics.com/v1/currencies/ticker?key=${widget.nomicsApi}&ids=${searchMap[item.title]}');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => (() {
                                          return Scaffold(
                                            appBar: AppBar(
                                              title: Text(
                                                item.title,
                                              ),
                                              backgroundColor: Theme.of(context)
                                                  .primaryColor,
                                              foregroundColor: Theme.of(context)
                                                  .appBarTheme
                                                  .toolbarTextStyle!
                                                  .color,
                                            ),
                                            body: ListView.builder(
                                                shrinkWrap: true,
                                                cacheExtent: 9999,
                                                physics:
                                                    const AlwaysScrollableScrollPhysics(),
                                                primary: false,
                                                itemCount: 1,
                                                itemBuilder:
                                                    (BuildContext context,
                                                        int index) {
                                                  if (kIsWeb) {
                                                    return FutureBuilder<List>(
                                                      future: searchResponse,
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot.hasData) {
                                                          aggregateList =
                                                              snapshot.data!;
                                                          return Wallet(
                                                            buttonActive: true,
                                                            notifyParent: widget
                                                                .notifyParent,
                                                            name: snapshot
                                                                    .data![1]
                                                                [index]["name"],
                                                            icon: "https://corsproxy.garvshah.workers.dev/?" +
                                                                snapshot.data![
                                                                            1]
                                                                        [index][
                                                                    "logo_url"],
                                                            rate: snapshot
                                                                    .data![1][
                                                                index]["price"],
                                                            day: double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["1d"][
                                                                    "price_change_pct"]),
                                                            week: double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["7d"][
                                                                    "price_change_pct"]),
                                                            month: double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["30d"][
                                                                    "price_change_pct"]),
                                                            year: double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["365d"]
                                                                    [
                                                                    "price_change_pct"]),
                                                            ytd: double.parse(
                                                                snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["ytd"][
                                                                    "price_change_pct"]),
                                                            color: color[0],
                                                            alt: snapshot
                                                                    .data![1]
                                                                [index]["id"],
                                                            colorHex: color[1],
                                                            data: (() {
                                                              if (snapshot
                                                                      .data![0]
                                                                      .chartData
                                                                      .isEmpty ==
                                                                  true) {
                                                                return null;
                                                              } else {
                                                                return snapshot
                                                                        .data![0]
                                                                        .chartData[
                                                                    index];
                                                              }
                                                            }()),
                                                            buy: true,
                                                            index: index,
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return SizedBox(
                                                            width: 20.0,
                                                            height: 288.0,
                                                            child: Card(
                                                                shape:
                                                                    const RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .all(
                                                                    Radius
                                                                        .circular(
                                                                            10),
                                                                  ),
                                                                ),
                                                                child: SizedBox(
                                                                  height: 25.0,
                                                                  width: 25.0,
                                                                  child: Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Padding(
                                                                        padding: const EdgeInsets.all(16.0),
                                                                        child: Text(
                                                                          '${snapshot.error}',
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        )),
                                                                  ),
                                                                )),
                                                          );
                                                        }

                                                        // By default, show a loading spinner.
                                                        return const SizedBox(
                                                          width: 20.0,
                                                          height: 288.0,
                                                          child: Card(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .all(
                                                                  Radius
                                                                      .circular(
                                                                          10),
                                                                ),
                                                              ),
                                                              child: SizedBox(
                                                                height: 25.0,
                                                                width: 25.0,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                ),
                                                              )),
                                                        );
                                                      },
                                                    );
                                                  } else {
                                                    return FutureBuilder<List>(
                                                      future: searchResponse,
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot.hasData) {
                                                          print(
                                                              "kim kim ${snapshot.data![1][index]["name"]} - ${snapshot.data![0].chartData.isEmpty}");

                                                          aggregateList =
                                                              snapshot.data!;
                                                          return Wallet(
                                                            buttonActive: true,
                                                            notifyParent: widget
                                                                .notifyParent,
                                                            name: snapshot
                                                                    .data![1]
                                                                [index]["name"],
                                                            icon: snapshot
                                                                        .data![
                                                                    1][index]
                                                                ["logo_url"],
                                                            rate: snapshot
                                                                    .data![1][
                                                                index]["price"],
                                                            day: (() {
                                                              try {
                                                                return double.parse(
                                                                    snapshot.data![1][index]
                                                                            [
                                                                            "1d"]
                                                                        [
                                                                        "price_change_pct"]);
                                                              } catch (err) {
                                                                return 0.0;
                                                              }
                                                            }()),
                                                            week: (() {
                                                              try {
                                                                return double.parse(
                                                                    snapshot.data![1][index]
                                                                            [
                                                                            "7d"]
                                                                        [
                                                                        "price_change_pct"]);
                                                              } catch (err) {
                                                                return 0.0;
                                                              }
                                                            }()),
                                                            month: (() {
                                                              try {
                                                                return double.parse(
                                                                    snapshot.data![1][index]
                                                                            [
                                                                            "30d"]
                                                                        [
                                                                        "price_change_pct"]);
                                                              } catch (err) {
                                                                return 0.0;
                                                              }
                                                            }()),
                                                            year: (() {
                                                              try {
                                                                return double.parse(snapshot.data![1]
                                                                            [
                                                                            index]
                                                                        ["365d"]
                                                                    [
                                                                    "price_change_pct"]);
                                                              } catch (err) {
                                                                return 0.0;
                                                              }
                                                            }()),
                                                            ytd: (() {
                                                              try {
                                                                return double.parse(
                                                                    snapshot.data![1][index]
                                                                            [
                                                                            "ytd"]
                                                                        [
                                                                        "price_change_pct"]);
                                                              } catch (err) {
                                                                return 0.0;
                                                              }
                                                            }()),
                                                            color: color[0],
                                                            alt: snapshot
                                                                    .data![1]
                                                                [index]["id"],
                                                            colorHex: color[1],
                                                            data: (() {
                                                              if (snapshot
                                                                      .data![0]
                                                                      .chartData
                                                                      .isEmpty ==
                                                                  true) {
                                                                return null;
                                                              } else {
                                                                return snapshot
                                                                        .data![0]
                                                                        .chartData[
                                                                    index];
                                                              }
                                                            }()),
                                                            buy: true,
                                                            index: index,
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return SizedBox(
                                                            width: 20.0,
                                                            height: 288.0,
                                                            child: Card(
                                                                shape:
                                                                    const RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .all(
                                                                    Radius
                                                                        .circular(
                                                                            10),
                                                                  ),
                                                                ),
                                                                child: SizedBox(
                                                                  height: 25.0,
                                                                  width: 25.0,
                                                                  child: Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    child: Padding(
                                                                        padding: const EdgeInsets.all(16.0),
                                                                        child: Text(
                                                                          '${snapshot.error}',
                                                                          textAlign:
                                                                              TextAlign.center,
                                                                        )),
                                                                  ),
                                                                )),
                                                          );
                                                        }

                                                        // By default, show a loading spinner.
                                                        return const SizedBox(
                                                          width: 20.0,
                                                          height: 288.0,
                                                          child: Card(
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .all(
                                                                  Radius
                                                                      .circular(
                                                                          10),
                                                                ),
                                                              ),
                                                              child: SizedBox(
                                                                height: 25.0,
                                                                width: 25.0,
                                                                child: Align(
                                                                  alignment:
                                                                      Alignment
                                                                          .center,
                                                                  child:
                                                                      CircularProgressIndicator(),
                                                                ),
                                                              )),
                                                        );
                                                      },
                                                    );
                                                  }
                                                }),
                                          );
                                        }())),
                              );

                              /*var idData = await fetchCharts(
                                  1,
                                  widget.nomicsApi,
                                  'https://api.nomics.com/v1/currencies/ticker?key=${widget.nomicsApi}&status=active');
                              var search = Search.fromJson(idData[1]);

                              Map<String, dynamic> map = search.map;

                              if (searchMap != map) {
                                await global.doc("search").set(
                                      map,
                                      SetOptions(merge: true),
                                    );
                              }*/
                            },
                            child: (() {
                              if (Theme.of(context).brightness ==
                                  Brightness.light) {
                                return Text(item.title);
                              } else {
                                return Text(
                                  item.title,
                                  style: const TextStyle(color: Colors.grey),
                                );
                              }
                            }()));
                      },
                    ),
                  );
                } else if (index == length * counter - 1) {
                  return const SizedBox(
                    width: 20.0,
                    height: 288.0,
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
                  index = index - 1;
                  if (kIsWeb) {
                    return FutureBuilder<List>(
                      future: futureCharts,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          aggregateList = snapshot.data!;
                          return Wallet(
                            buttonActive: true,
                            notifyParent: widget.notifyParent,
                            name: snapshot.data![1][index]["name"],
                            icon: "https://corsproxy.garvshah.workers.dev/?" +
                                snapshot.data![1][index]["logo_url"],
                            rate: snapshot.data![1][index]["price"],
                            day: (() {
                              if (snapshot.data![1][index]["1d"] == null) {
                                return null;
                              } else {
                                return double.parse(snapshot.data![1][index]
                                    ["1d"]["price_change_pct"]);
                              }
                            }()),
                            week: (() {
                              if (snapshot.data![1][index]["7d"] == null) {
                                return null;
                              } else {
                                return double.parse(snapshot.data![1][index]
                                    ["7d"]["price_change_pct"]);
                              }
                            }()),
                            month: (() {
                              if (snapshot.data![1][index]["30d"] == null) {
                                return null;
                              } else {
                                return double.parse(snapshot.data![1][index]
                                    ["30d"]["price_change_pct"]);
                              }
                            }()),
                            year: (() {
                              if (snapshot.data![1][index]["365d"] == null) {
                                return null;
                              } else {
                                return double.parse(snapshot.data![1][index]
                                    ["365d"]["price_change_pct"]);
                              }
                            }()),
                            ytd: (() {
                              if (snapshot.data![1][index]["ytd"] == null) {
                                return null;
                              } else {
                                return double.parse(snapshot.data![1][index]
                                    ["ytd"]["price_change_pct"]);
                              }
                            }()),
                            color: color[0],
                            alt: snapshot.data![1][index]["id"],
                            colorHex: color[1],
                            data: (() {
                              if (snapshot.data![0].chartData.isEmpty == true) {
                                return null;
                              } else {
                                return snapshot.data![0].chartData[index];
                              }
                            }()),
                            buy: true,
                            index: index,
                          );
                        } else if (snapshot.hasError) {
                          return SizedBox(
                            width: 20.0,
                            height: 288.0,
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
                          height: 288.0,
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
                  } else {
                    return FutureBuilder<List>(
                      future: futureCharts,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          aggregateList = snapshot.data!;
                          return Wallet(
                            buttonActive: true,
                            notifyParent: widget.notifyParent,
                            name: snapshot.data![1][index]["name"],
                            icon: snapshot.data![1][index]["logo_url"],
                            rate: snapshot.data![1][index]["price"],
                            day: (() {
                              try {
                                return double.parse(snapshot.data![1][index]
                                    ["1d"]["price_change_pct"]);
                              } catch (err) {
                                return 0.0;
                              }
                            }()),
                            week: (() {
                              try {
                                return double.parse(snapshot.data![1][index]
                                    ["7d"]["price_change_pct"]);
                              } catch (err) {
                                return 0.0;
                              }
                            }()),
                            month: (() {
                              try {
                                return double.parse(snapshot.data![1][index]
                                    ["30d"]["price_change_pct"]);
                              } catch (err) {
                                return 0.0;
                              }
                            }()),
                            year: (() {
                              try {
                                return double.parse(snapshot.data![1][index]
                                    ["365d"]["price_change_pct"]);
                              } catch (err) {
                                return 0.0;
                              }
                            }()),
                            ytd: (() {
                              try {
                                return double.parse(snapshot.data![1][index]
                                    ["ytd"]["price_change_pct"]);
                              } catch (err) {
                                return 0.0;
                              }
                            }()),
                            color: color[0],
                            alt: snapshot.data![1][index]["id"],
                            colorHex: color[1],
                            data: (() {
                              if (snapshot.data![0].chartData.isEmpty == true) {
                                return null;
                              } else {
                                return snapshot.data![0].chartData[index];
                              }
                            }()),
                            buy: true,
                            index: index,
                          );
                        } else if (snapshot.hasError) {
                          return SizedBox(
                            width: 20.0,
                            height: 288.0,
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
                          height: 288.0,
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
              }),
          onRefresh: () {
            return Future.delayed(const Duration(seconds: 0), () async {
              var chartData = await fetchCharts(1, widget.nomicsApi);
              setState(() {
                futureCharts = Future.delayed(const Duration(seconds: 0), () {
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
