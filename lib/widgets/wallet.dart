import 'dart:math';
import 'package:nova/util/const.dart';
import 'package:nova/widgets/custom_expansion_tile.dart' as custom;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:statusbarz/statusbarz.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


FirebaseFirestore firestore = FirebaseFirestore.instance;
late Map<String, dynamic> userData;
var fireStoreUserRef = FirebaseFirestore.instance
    .collection('users')
    .doc(FirebaseAuth.instance.currentUser!.uid);

enum timeInterval { day, week, month, year, ytd }
timeInterval defaultInt = timeInterval.year;
timeInterval interval = defaultInt;

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

void main() => runApp(const Wallet());

void updateCharts() {}

enum mode { graphUniform, uniform, rainbow }

var uniformColour = "011469";

class PointModel {
  final num pointX;
  final num pointY;

  PointModel({required this.pointX, required this.pointY});
}

class Config {
  static final List<PointModel> _chartDataList = [];
  static bool _loaded = false;
  static var colourMode = mode.rainbow;

  static isLoaded() {
    return _loaded;
  }

  static getMode() {
    return colourMode;
  }

  static chartRefresh() {
    _loaded = false;
    Statusbarz.instance.refresh();
  }

  static loadChartDataList() async {
    // fetch data from web ...
    await loadFromWeb();
    _loaded = true;
  }

  static loadFromWeb() {
    // but here i will add test data
    _chartDataList.clear();
  }

  static getChartDataList() {
    if (!_loaded) loadChartDataList();
    return _chartDataList;
  }
}

class Wallet extends StatefulWidget {
  final String? name;
  final String? icon;
  final String? rate;
  final String? alt;
  final String? colorHex;
  final double? day;
  final String? altRate;
  final double? week;
  final double? month;
  final double? year;
  final double? ytd;
  final bool? buy;
  final charts.Color? color;
  final List<PointModel>? data;
  const Wallet(
      {Key? key,
      this.name,
      this.icon,
      this.rate,
      this.color,
        this.altRate,
      this.alt,
      this.colorHex,
      this.day,
      this.week,
      this.month,
      this.year,
      this.ytd,
      this.buy,
      this.data})
      : super(key: key);

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  final List<charts.Series<PointModel, num>> _chartDataSeries = [];
  List<PointModel> chartDataList = [];
  Widget lineChart = const Text("");
  late TextEditingController inputController;
  final List color =
      Constants.matColors[Random().nextInt(Constants.matColors.length)];
  bool graphState = false;

  @override
  void initState() {
    super.initState();
    inputController = TextEditingController();
    WidgetsBinding.instance!.addPostFrameCallback((_) => setState(() {
          chartDataList = widget.data!;
          _chartDataSeries.clear();
          bool setIconColour = false;
          bool setGraphColour = false;

          if (Config.getMode() == mode.uniform) {
            setIconColour = true;
            setGraphColour = true;
          } else if (Config.getMode() == mode.graphUniform) {
            setGraphColour = true;
            color[1] = "";
          }

          if (setGraphColour == true) {
            color[0] =
                charts.ColorUtil.fromDartColor(HexColor.fromHex(uniformColour));
          }

          if (setIconColour == true) {
            color[1] = uniformColour;
          }

          // construct you're chart data series
          _chartDataSeries.add(
            charts.Series<PointModel, num>(
              colorFn: (_, __) => color[0]!,
              id: '${widget.name}',
              data: chartDataList,
              domainFn: (PointModel pointModel, _) => pointModel.pointX,
              measureFn: (PointModel pointModel, _) => pointModel.pointY,
            ),
          );

          // now change the 'Loading...' widget with the real chart widget
          lineChart = charts.LineChart(
            _chartDataSeries,
            defaultRenderer:
                charts.LineRendererConfig(includeArea: true, stacked: true),
            animate: true,
            animationDuration: const Duration(milliseconds: 500),
            primaryMeasureAxis: const charts.NumericAxisSpec(
              renderSpec: charts.NoneRenderSpec(),
            ),
            domainAxis: const charts.NumericAxisSpec(
//                showAxisLine: true,
              renderSpec: charts.NoneRenderSpec(),
            ),
          );
        }));
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  bool _customTileExpanded = false;

  @override
  Widget build(BuildContext context) {
    double priceChange;

    if (interval == timeInterval.day) {
      priceChange = widget.day!;
    } else if (interval == timeInterval.week) {
      priceChange = widget.week!;
    } else if (interval == timeInterval.month) {
      priceChange = widget.month!;
    } else if (interval == timeInterval.year) {
      priceChange = widget.year!;
    } else if (interval == timeInterval.ytd) {
      priceChange = widget.ytd!;
    } else {
      priceChange = widget.year!;
    }
    // this is where i use Config class to perform my asynchronous load data
    // and check if it's loaded so this section will occur only once
    // here return your widget where the chart is drawn
    return Card(
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: ListTileTheme(
        contentPadding: const EdgeInsets.all(0),
        child: custom.ExpansionTile(
          buySellButton: (() {
            if (widget.buy == true) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (graphState == false) {
                      lineChart = Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            FutureBuilder<DocumentSnapshot>(
                              future: users
                                  .doc(
                                  FirebaseAuth.instance.currentUser!.uid)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<
                                      DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return const Text("Something went wrong");
                                }

                                if (snapshot.hasData &&
                                    !snapshot.data!.exists) {
                                  return const Text(
                                      "Document does not exist");
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  Map<String, dynamic> data = snapshot.data!
                                      .data() as Map<String, dynamic>;

                                  userData = data;

                                  return Text(
                                      "You have ${data['USD']} USD available");
                                }

                                return const CircularProgressIndicator();
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              width: 250,
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'How much to spend?',
                                ),
                                controller: inputController,
                                onSubmitted: (String value) async {
                                  if (value == "all") {
                                    value = userData['USD'].toString();
                                  }

                                  if (value != "") {
                                    if (userData['USD'] -
                                        double.parse(value) >=
                                        0) {
                                      userData['assets'].add(widget.alt);
                                      await fireStoreUserRef.update({
                                        'assets': userData['assets']
                                            .toSet()
                                            .toList()
                                      });
                                      if (userData['${widget.alt}'] ==
                                          null) {
                                        await fireStoreUserRef.update({
                                          '${widget.alt}':
                                          double.parse(value) /
                                              double.parse(widget.rate!)
                                        });
                                      } else {
                                        await fireStoreUserRef.update({
                                          '${widget.alt}': userData[
                                          '${widget.alt}'] +
                                              double.parse(value) /
                                                  double.parse(widget.rate!)
                                        });
                                      }

                                      await fireStoreUserRef.update({
                                        'USD': userData['USD'] -
                                            double.parse(value)
                                      });

                                      await showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Thanks!'),
                                            content: Text(
                                                'You spent $value on ${widget
                                                    .name}!'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    chartDataList =
                                                    widget.data!;
                                                    _chartDataSeries
                                                        .clear();
                                                    bool setIconColour =
                                                    false;
                                                    bool setGraphColour =
                                                    false;

                                                    if (Config.getMode() ==
                                                        mode.uniform) {
                                                      setIconColour = true;
                                                      setGraphColour = true;
                                                    } else if (Config
                                                        .getMode() ==
                                                        mode.graphUniform) {
                                                      setGraphColour = true;
                                                      color[1] = "";
                                                    }

                                                    if (setGraphColour ==
                                                        true) {
                                                      color[0] = charts
                                                          .ColorUtil
                                                          .fromDartColor(
                                                          HexColor.fromHex(
                                                              uniformColour));
                                                    }

                                                    if (setIconColour ==
                                                        true) {
                                                      color[1] =
                                                          uniformColour;
                                                    }

                                                    // construct you're chart data series
                                                    _chartDataSeries.add(
                                                      charts.Series<
                                                          PointModel,
                                                          num>(
                                                        colorFn: (_, __) =>
                                                        color[0]!,
                                                        id: '${widget
                                                            .name}',
                                                        data: chartDataList,
                                                        domainFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointX,
                                                        measureFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointY,
                                                      ),
                                                    );

                                                    // now change the 'Loading...' widget with the real chart widget
                                                    lineChart =
                                                        charts.LineChart(
                                                          _chartDataSeries,
                                                          defaultRenderer: charts
                                                              .LineRendererConfig(
                                                              includeArea:
                                                              true,
                                                              stacked: true),
                                                          animate: true,
                                                          animationDuration:
                                                          const Duration(
                                                              milliseconds:
                                                              500),
                                                          primaryMeasureAxis:
                                                          const charts
                                                              .NumericAxisSpec(
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                          domainAxis: const charts
                                                              .NumericAxisSpec(
//                showAxisLine: true,
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                        );
                                                  });
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      await showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Sorry!'),
                                            content: const Text(
                                                "You don't have enough money for this transaction :("),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    chartDataList =
                                                    widget.data!;
                                                    _chartDataSeries
                                                        .clear();
                                                    bool setIconColour =
                                                    false;
                                                    bool setGraphColour =
                                                    false;

                                                    if (Config.getMode() ==
                                                        mode.uniform) {
                                                      setIconColour = true;
                                                      setGraphColour = true;
                                                    } else if (Config
                                                        .getMode() ==
                                                        mode.graphUniform) {
                                                      setGraphColour = true;
                                                      color[1] = "";
                                                    }

                                                    if (setGraphColour ==
                                                        true) {
                                                      color[0] = charts
                                                          .ColorUtil
                                                          .fromDartColor(
                                                          HexColor.fromHex(
                                                              uniformColour));
                                                    }

                                                    if (setIconColour ==
                                                        true) {
                                                      color[1] =
                                                          uniformColour;
                                                    }

                                                    // construct you're chart data series
                                                    _chartDataSeries.add(
                                                      charts.Series<
                                                          PointModel,
                                                          num>(
                                                        colorFn: (_, __) =>
                                                        color[0]!,
                                                        id: '${widget
                                                            .name}',
                                                        data: chartDataList,
                                                        domainFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointX,
                                                        measureFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointY,
                                                      ),
                                                    );

                                                    // now change the 'Loading...' widget with the real chart widget
                                                    lineChart =
                                                        charts.LineChart(
                                                          _chartDataSeries,
                                                          defaultRenderer: charts
                                                              .LineRendererConfig(
                                                              includeArea:
                                                              true,
                                                              stacked: true),
                                                          animate: true,
                                                          animationDuration:
                                                          const Duration(
                                                              milliseconds:
                                                              500),
                                                          primaryMeasureAxis:
                                                          const charts
                                                              .NumericAxisSpec(
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                          domainAxis: const charts
                                                              .NumericAxisSpec(
//                showAxisLine: true,
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                        );
                                                  });
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  } else {
                                    setState(() {
                                      chartDataList = widget.data!;
                                      _chartDataSeries.clear();
                                      bool setIconColour = false;
                                      bool setGraphColour = false;

                                      if (Config.getMode() ==
                                          mode.uniform) {
                                        setIconColour = true;
                                        setGraphColour = true;
                                      } else if (Config.getMode() ==
                                          mode.graphUniform) {
                                        setGraphColour = true;
                                        color[1] = "";
                                      }

                                      if (setGraphColour == true) {
                                        color[0] =
                                            charts.ColorUtil.fromDartColor(
                                                HexColor.fromHex(
                                                    uniformColour));
                                      }

                                      if (setIconColour == true) {
                                        color[1] = uniformColour;
                                      }

                                      // construct you're chart data series
                                      _chartDataSeries.add(
                                        charts.Series<PointModel, num>(
                                          colorFn: (_, __) => color[0]!,
                                          id: '${widget.name}',
                                          data: chartDataList,
                                          domainFn:
                                              (PointModel pointModel, _) =>
                                          pointModel.pointX,
                                          measureFn:
                                              (PointModel pointModel, _) =>
                                          pointModel.pointY,
                                        ),
                                      );

                                      // now change the 'Loading...' widget with the real chart widget
                                      lineChart = charts.LineChart(
                                        _chartDataSeries,
                                        defaultRenderer:
                                        charts.LineRendererConfig(
                                            includeArea: true,
                                            stacked: true),
                                        animate: true,
                                        animationDuration:
                                        const Duration(milliseconds: 500),
                                        primaryMeasureAxis:
                                        const charts.NumericAxisSpec(
                                          renderSpec: charts
                                              .NoneRenderSpec(),
                                        ),
                                        domainAxis:
                                        const charts.NumericAxisSpec(
//                showAxisLine: true,
                                          renderSpec: charts
                                              .NoneRenderSpec(),
                                        ),
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                      graphState = true;
                    } else {
                      chartDataList = widget.data!;
                      _chartDataSeries.clear();
                      bool setIconColour = false;
                      bool setGraphColour = false;

                      if (Config.getMode() == mode.uniform) {
                        setIconColour = true;
                        setGraphColour = true;
                      } else if (Config.getMode() == mode.graphUniform) {
                        setGraphColour = true;
                        color[1] = "";
                      }

                      if (setGraphColour == true) {
                        color[0] =
                            charts.ColorUtil.fromDartColor(HexColor.fromHex(uniformColour));
                      }

                      if (setIconColour == true) {
                        color[1] = uniformColour;
                      }

                      // construct you're chart data series
                      _chartDataSeries.add(
                        charts.Series<PointModel, num>(
                          colorFn: (_, __) => color[0]!,
                          id: '${widget.name}',
                          data: chartDataList,
                          domainFn: (PointModel pointModel, _) => pointModel.pointX,
                          measureFn: (PointModel pointModel, _) => pointModel.pointY,
                        ),
                      );

                      // now change the 'Loading...' widget with the real chart widget
                      lineChart = charts.LineChart(
                        _chartDataSeries,
                        defaultRenderer:
                        charts.LineRendererConfig(includeArea: true, stacked: true),
                        animate: true,
                        animationDuration: const Duration(milliseconds: 500),
                        primaryMeasureAxis: const charts.NumericAxisSpec(
                          renderSpec: charts.NoneRenderSpec(),
                        ),
                        domainAxis: const charts.NumericAxisSpec(
//                showAxisLine: true,
                          renderSpec: charts.NoneRenderSpec(),
                        ),
                      );

                      graphState = false;
                    }
                  });
                },
                child: Container(
                  height: 30.0,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Stack(
                    children: [
                      Center(
                          child: Text('Buy',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.secondary)),
                        ),
                    ],
                  ),
                ),
              );
            } else {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (graphState == false) {
                      lineChart = Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            FutureBuilder<DocumentSnapshot>(
                              future: users
                                  .doc(
                                  FirebaseAuth.instance.currentUser!.uid)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<
                                      DocumentSnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  return const Text("Something went wrong");
                                }

                                if (snapshot.hasData &&
                                    !snapshot.data!.exists) {
                                  return const Text(
                                      "Document does not exist");
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  Map<String, dynamic> data = snapshot.data!
                                      .data() as Map<String, dynamic>;

                                  userData = data;

                                  return Text(
                                      "You have ${data[widget.alt]} ${widget.name} available");
                                }

                                return const CircularProgressIndicator();
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              width: 250,
                              child: TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'How much to sell?',
                                ),
                                controller: inputController,
                                onSubmitted: (String value) async {
                                  var all = false;
                                  if (value == "all") {
                                    value = userData[widget.alt].toString();
                                    all = true;
                                  }

                                  if (value != "") {
                                    if (userData[widget.alt] -
                                        double.parse(value) >
                                        0) {
                                      await fireStoreUserRef.update({
                                        'USD': userData['USD'] + (double.parse(value) *
                                            double.parse(widget.altRate!))
                                      });

                                      await fireStoreUserRef.update({
                                        '${widget.alt}': userData[widget.alt] -
                                            double.parse(value)
                                      });

                                      await showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Thanks!'),
                                            content: Text(
                                                'You withdrew $value from ${widget
                                                    .name}, and got ${double.parse(value) *
                                                    double.parse(widget.altRate!)} USD!'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    chartDataList =
                                                    widget.data!;
                                                    _chartDataSeries
                                                        .clear();
                                                    bool setIconColour =
                                                    false;
                                                    bool setGraphColour =
                                                    false;

                                                    if (Config.getMode() ==
                                                        mode.uniform) {
                                                      setIconColour = true;
                                                      setGraphColour = true;
                                                    } else if (Config
                                                        .getMode() ==
                                                        mode.graphUniform) {
                                                      setGraphColour = true;
                                                      color[1] = "";
                                                    }

                                                    if (setGraphColour ==
                                                        true) {
                                                      color[0] = charts
                                                          .ColorUtil
                                                          .fromDartColor(
                                                          HexColor.fromHex(
                                                              uniformColour));
                                                    }

                                                    if (setIconColour ==
                                                        true) {
                                                      color[1] =
                                                          uniformColour;
                                                    }

                                                    // construct you're chart data series
                                                    _chartDataSeries.add(
                                                      charts.Series<
                                                          PointModel,
                                                          num>(
                                                        colorFn: (_, __) =>
                                                        color[0]!,
                                                        id: '${widget
                                                            .name}',
                                                        data: chartDataList,
                                                        domainFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointX,
                                                        measureFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointY,
                                                      ),
                                                    );

                                                    // now change the 'Loading...' widget with the real chart widget
                                                    lineChart =
                                                        charts.LineChart(
                                                          _chartDataSeries,
                                                          defaultRenderer: charts
                                                              .LineRendererConfig(
                                                              includeArea:
                                                              true,
                                                              stacked: true),
                                                          animate: true,
                                                          animationDuration:
                                                          const Duration(
                                                              milliseconds:
                                                              500),
                                                          primaryMeasureAxis:
                                                          const charts
                                                              .NumericAxisSpec(
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                          domainAxis: const charts
                                                              .NumericAxisSpec(
                //                showAxisLine: true,
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                        );
                                                  });
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else if (userData[widget.alt] -
                                        double.parse(value) ==
                                        0 || all) {
                                      await fireStoreUserRef.update({
                                        'USD': userData['USD'] + (userData[widget.alt] *
                                            double.parse(widget.altRate!))
                                      });

                                      await fireStoreUserRef.update({
                                        '${widget.alt}': 0
                                      });

                                      userData['assets'].remove(widget.alt);

                                      await fireStoreUserRef.update({
                                        'assets': userData['assets']
                                      });

                                      await showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Thanks!'),
                                            content: Text(
                                                'You withdrew $value from ${widget
                                                    .name}, and got ${double.parse(value) *
                                                    double.parse(widget.altRate!)} USD!'),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    chartDataList =
                                                    widget.data!;
                                                    _chartDataSeries
                                                        .clear();
                                                    bool setIconColour =
                                                    false;
                                                    bool setGraphColour =
                                                    false;

                                                    if (Config.getMode() ==
                                                        mode.uniform) {
                                                      setIconColour = true;
                                                      setGraphColour = true;
                                                    } else if (Config
                                                        .getMode() ==
                                                        mode.graphUniform) {
                                                      setGraphColour = true;
                                                      color[1] = "";
                                                    }

                                                    if (setGraphColour ==
                                                        true) {
                                                      color[0] = charts
                                                          .ColorUtil
                                                          .fromDartColor(
                                                          HexColor.fromHex(
                                                              uniformColour));
                                                    }

                                                    if (setIconColour ==
                                                        true) {
                                                      color[1] =
                                                          uniformColour;
                                                    }

                                                    // construct you're chart data series
                                                    _chartDataSeries.add(
                                                      charts.Series<
                                                          PointModel,
                                                          num>(
                                                        colorFn: (_, __) =>
                                                        color[0]!,
                                                        id: '${widget
                                                            .name}',
                                                        data: chartDataList,
                                                        domainFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointX,
                                                        measureFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointY,
                                                      ),
                                                    );

                                                    // now change the 'Loading...' widget with the real chart widget
                                                    lineChart =
                                                        charts.LineChart(
                                                          _chartDataSeries,
                                                          defaultRenderer: charts
                                                              .LineRendererConfig(
                                                              includeArea:
                                                              true,
                                                              stacked: true),
                                                          animate: true,
                                                          animationDuration:
                                                          const Duration(
                                                              milliseconds:
                                                              500),
                                                          primaryMeasureAxis:
                                                          const charts
                                                              .NumericAxisSpec(
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                          domainAxis: const charts
                                                              .NumericAxisSpec(
                //                showAxisLine: true,
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                        );
                                                  });
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } else {
                                      await showDialog<void>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Sorry!'),
                                            content: const Text(
                                                "You don't have enough money for this transaction :("),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    chartDataList =
                                                    widget.data!;
                                                    _chartDataSeries
                                                        .clear();
                                                    bool setIconColour =
                                                    false;
                                                    bool setGraphColour =
                                                    false;

                                                    if (Config.getMode() ==
                                                        mode.uniform) {
                                                      setIconColour = true;
                                                      setGraphColour = true;
                                                    } else if (Config
                                                        .getMode() ==
                                                        mode.graphUniform) {
                                                      setGraphColour = true;
                                                      color[1] = "";
                                                    }

                                                    if (setGraphColour ==
                                                        true) {
                                                      color[0] = charts
                                                          .ColorUtil
                                                          .fromDartColor(
                                                          HexColor.fromHex(
                                                              uniformColour));
                                                    }

                                                    if (setIconColour ==
                                                        true) {
                                                      color[1] =
                                                          uniformColour;
                                                    }

                                                    // construct you're chart data series
                                                    _chartDataSeries.add(
                                                      charts.Series<
                                                          PointModel,
                                                          num>(
                                                        colorFn: (_, __) =>
                                                        color[0]!,
                                                        id: '${widget
                                                            .name}',
                                                        data: chartDataList,
                                                        domainFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointX,
                                                        measureFn: (PointModel
                                                        pointModel,
                                                            _) =>
                                                        pointModel.pointY,
                                                      ),
                                                    );

                                                    // now change the 'Loading...' widget with the real chart widget
                                                    lineChart =
                                                        charts.LineChart(
                                                          _chartDataSeries,
                                                          defaultRenderer: charts
                                                              .LineRendererConfig(
                                                              includeArea:
                                                              true,
                                                              stacked: true),
                                                          animate: true,
                                                          animationDuration:
                                                          const Duration(
                                                              milliseconds:
                                                              500),
                                                          primaryMeasureAxis:
                                                          const charts
                                                              .NumericAxisSpec(
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                          domainAxis: const charts
                                                              .NumericAxisSpec(
                //                showAxisLine: true,
                                                            renderSpec: charts
                                                                .NoneRenderSpec(),
                                                          ),
                                                        );
                                                  });
                                                },
                                                child: const Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  } else {
                                    setState(() {
                                      chartDataList = widget.data!;
                                      _chartDataSeries.clear();
                                      bool setIconColour = false;
                                      bool setGraphColour = false;

                                      if (Config.getMode() ==
                                          mode.uniform) {
                                        setIconColour = true;
                                        setGraphColour = true;
                                      } else if (Config.getMode() ==
                                          mode.graphUniform) {
                                        setGraphColour = true;
                                        color[1] = "";
                                      }

                                      if (setGraphColour == true) {
                                        color[0] =
                                            charts.ColorUtil.fromDartColor(
                                                HexColor.fromHex(
                                                    uniformColour));
                                      }

                                      if (setIconColour == true) {
                                        color[1] = uniformColour;
                                      }

                                      // construct you're chart data series
                                      _chartDataSeries.add(
                                        charts.Series<PointModel, num>(
                                          colorFn: (_, __) => color[0]!,
                                          id: '${widget.name}',
                                          data: chartDataList,
                                          domainFn:
                                              (PointModel pointModel, _) =>
                                          pointModel.pointX,
                                          measureFn:
                                              (PointModel pointModel, _) =>
                                          pointModel.pointY,
                                        ),
                                      );

                                      // now change the 'Loading...' widget with the real chart widget
                                      lineChart = charts.LineChart(
                                        _chartDataSeries,
                                        defaultRenderer:
                                        charts.LineRendererConfig(
                                            includeArea: true,
                                            stacked: true),
                                        animate: true,
                                        animationDuration:
                                        const Duration(milliseconds: 500),
                                        primaryMeasureAxis:
                                        const charts.NumericAxisSpec(
                                          renderSpec: charts
                                              .NoneRenderSpec(),
                                        ),
                                        domainAxis:
                                        const charts.NumericAxisSpec(
                //                showAxisLine: true,
                                          renderSpec: charts
                                              .NoneRenderSpec(),
                                        ),
                                      );
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                      graphState = true;
                    } else {
                      chartDataList = widget.data!;
                      _chartDataSeries.clear();
                      bool setIconColour = false;
                      bool setGraphColour = false;

                      if (Config.getMode() == mode.uniform) {
                        setIconColour = true;
                        setGraphColour = true;
                      } else if (Config.getMode() == mode.graphUniform) {
                        setGraphColour = true;
                        color[1] = "";
                      }

                      if (setGraphColour == true) {
                        color[0] =
                            charts.ColorUtil.fromDartColor(HexColor.fromHex(uniformColour));
                      }

                      if (setIconColour == true) {
                        color[1] = uniformColour;
                      }

                      // construct you're chart data series
                      _chartDataSeries.add(
                        charts.Series<PointModel, num>(
                          colorFn: (_, __) => color[0]!,
                          id: '${widget.name}',
                          data: chartDataList,
                          domainFn: (PointModel pointModel, _) => pointModel.pointX,
                          measureFn: (PointModel pointModel, _) => pointModel.pointY,
                        ),
                      );

                      // now change the 'Loading...' widget with the real chart widget
                      lineChart = charts.LineChart(
                        _chartDataSeries,
                        defaultRenderer:
                        charts.LineRendererConfig(includeArea: true, stacked: true),
                        animate: true,
                        animationDuration: const Duration(milliseconds: 500),
                        primaryMeasureAxis: const charts.NumericAxisSpec(
                          renderSpec: charts.NoneRenderSpec(),
                        ),
                        domainAxis: const charts.NumericAxisSpec(
//                showAxisLine: true,
                          renderSpec: charts.NoneRenderSpec(),
                        ),
                      );

                      graphState = false;
                    }
                  });
                },
                child: Container(
                  height: 30.0,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ),
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text('Sell',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary)),
                      ),
                    ],
                  ),
                ),
              );
            }
          }()),
          onExpansionChanged: (bool expanded) {
            setState(() {
              _customTileExpanded = expanded;
              interval = defaultInt;
            });
          },
          linechart: lineChart,
          trailing: Padding(
            padding: const EdgeInsets.fromLTRB(0, 7, 16.2, 0),
            child: Icon(
              _customTileExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
          ),
          //trailing: const SizedBox.shrink(),
          title: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        SizedBox(
                            child: CachedNetworkImage(
                              imageUrl: "${widget.icon}",
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(),
                              errorWidget: (context, url, error) => (() {
                                try {
                                  return SvgPicture.network(
                                    "${widget.icon}",
                                    semanticsLabel: 'crypto logo',
                                    placeholderBuilder:
                                        (BuildContext context) =>
                                            const CircularProgressIndicator(),
                                  );
                                } catch (error) {
                                  return const Icon(Icons.error);
                                }
                              }()),
                            ),
                            height: 25.0,
                            width: 25.0),
                        /*FadeInImage(
                      image: NetworkImage("https://cryptoicons.org/api/icon/${widget.alt!.toLowerCase()}/100/${color[1]!.toLowerCase()}", scale: 4),
                      placeholder: const AssetImage('assets/placeholder.png'),
                    )*/
                        const SizedBox(width: 10),
                        SizedBox(
                          width: (MediaQuery.of(context).size.width) * (2 / 5) -
                              22.5,
                          child: Text(
                            "${widget.name}",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(context)
                                  .appBarTheme
                                  .toolbarTextStyle!
                                  .color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width:
                          (MediaQuery.of(context).size.width) * (2 / 5) - 22.5,
                      height: 25.0,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${widget.rate}",
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .appBarTheme
                                .toolbarTextStyle!
                                .color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 2, 5),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    (() {
                      if (widget.buy!) {
                        if (priceChange > 0) {
                          return Icon(Icons.arrow_drop_up_rounded, color: Colors.green[400]);
                        } else {
                          return Icon(Icons.arrow_drop_down_rounded, color: Colors.red[400]);
                        }
                      } else {
                        return const Text("");
                      }
                    }()),
                    (() {
                      if (widget.buy!) {
                        return Text(
                          "(${(priceChange * 100).toStringAsFixed(
                              2)}%) ${(priceChange * double.parse(widget.rate!))
                              .toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: (() {
                              if (priceChange > 0) {
                                return Colors.green[400];
                              } else {
                                return Colors.red[400];
                              }
                            }()),
                          ),
                        );
                      } else {
                        return Text(
                          "Value in USD: " + (double.parse(widget.altRate!) * double.parse(widget.rate!)).toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        );
                      }
                    }()),
                  ],
                ),
              ),
            ],
          ),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    setState(() {
                      interval = timeInterval.day;
                    });
                  },
                  child: (() {
                    if (interval == timeInterval.day) {
                      return Text('Day',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary));
                    } else {
                      return const Text('Day',
                          style: TextStyle(color: Colors.grey));
                    }
                  }()),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    setState(() {
                      interval = timeInterval.week;
                    });
                  },
                  child: (() {
                    if (interval == timeInterval.week) {
                      return Text('Week',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary));
                    } else {
                      return const Text('Week',
                          style: TextStyle(color: Colors.grey));
                    }
                  }()),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    setState(() {
                      interval = timeInterval.month;
                    });
                  },
                  child: (() {
                    if (interval == timeInterval.month) {
                      return Text('Month',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary));
                    } else {
                      return const Text('Month',
                          style: TextStyle(color: Colors.grey));
                    }
                  }()),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    setState(() {
                      interval = timeInterval.year;
                    });
                  },
                  child: (() {
                    if (interval == timeInterval.year) {
                      return Text('Year',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary));
                    } else {
                      return const Text('Year',
                          style: TextStyle(color: Colors.grey));
                    }
                  }()),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    setState(() {
                      interval = timeInterval.ytd;
                    });
                  },
                  child: (() {
                    if (interval == timeInterval.ytd) {
                      return Text('YTD',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary));
                    } else {
                      return const Text('YTD',
                          style: TextStyle(color: Colors.grey));
                    }
                  }()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
