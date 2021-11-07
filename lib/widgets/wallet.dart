import 'dart:math';
import 'package:nova/util/const.dart';
import 'package:nova/widgets/custom_expansion_tile.dart' as custom;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:statusbarz/statusbarz.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum timeInterval { day, week, month, year, ytd }
timeInterval defaultInt = timeInterval.week;
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
  final double? week;
  final double? month;
  final double? year;
  final double? ytd;
  final charts.Color? color;
  final List<PointModel>? data;
  const Wallet(
      {Key? key,
      this.name,
      this.icon,
      this.rate,
      this.color,
      this.alt,
      this.colorHex,
      this.day,
      this.week,
      this.month,
      this.year,
      this.ytd,
      this.data})
      : super(key: key);

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  final List<charts.Series<PointModel, num>> _chartDataSeries = [];
  List<PointModel> chartDataList = [];
  Widget lineChart = const Text("");
  final List color =
      Constants.matColors[Random().nextInt(Constants.matColors.length)];

  @override
  void initState() {
    super.initState();
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

  bool _customTileExpanded = false;

  @override
  Widget build(BuildContext context) {
    double priceChange;

    if (interval == timeInterval.day) {
      priceChange = widget.day!;
      print("issa day");
    } else if (interval == timeInterval.week) {
      priceChange = widget.week!;
      print("issa week");
    } else if (interval == timeInterval.month) {
      priceChange = widget.month!;
      print("issa month");
    } else if (interval == timeInterval.year) {
      priceChange = widget.year!;
      print("issa year");
    } else if (interval == timeInterval.ytd) {
      priceChange = widget.ytd!;
      print("issa ytd");
    } else {
      print("what's happening");
      priceChange = widget.week!;
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
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
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
                              18.5,
                          child: Text(
                            "${widget.name}",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 20,
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
                          (MediaQuery.of(context).size.width) * (2 / 5) - 18.5,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 5),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(" "),
                    Text(
                      "(${(priceChange * 100).toStringAsFixed(2)}%) ${(priceChange * double.parse(widget.rate!)).toStringAsFixed(2)}",
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
                    ),
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
                    textStyle: const TextStyle(fontSize: 20),
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
                    textStyle: const TextStyle(fontSize: 20),
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
                    textStyle: const TextStyle(fontSize: 20),
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
                    textStyle: const TextStyle(fontSize: 20),
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
                    textStyle: const TextStyle(fontSize: 20),
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
