import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class Constants {
  static String appName = "Nova System";

  static const regularHeading = TextStyle(
      fontSize: 18.0, fontWeight: FontWeight.w600, color: Colors.black);

  static const boldHeading = TextStyle(
      fontSize: 22.0, fontWeight: FontWeight.w600, color: Colors.white);

  static const regularDarkText = TextStyle(
      fontSize: 16.0, fontWeight: FontWeight.w600, color: Colors.black);

  static List matColors = [
    [charts.MaterialPalette.indigo.shadeDefault, "3f51b5"],
    [charts.MaterialPalette.blue.shadeDefault, "2196f3"],
    [charts.MaterialPalette.cyan.shadeDefault, "00bcd4"],
    [charts.MaterialPalette.deepOrange.shadeDefault, "ff5722"],
    [charts.MaterialPalette.green.shadeDefault, "4caf50"],
    [charts.MaterialPalette.lime.shadeDefault, "cddc39"],
    [charts.MaterialPalette.pink.shadeDefault, "e91e63"],
    [charts.MaterialPalette.purple.shadeDefault, "9c27b0"],
    [charts.MaterialPalette.red.shadeDefault, "f44336"],
    [charts.MaterialPalette.teal.shadeDefault, "009688"],
    [charts.MaterialPalette.yellow.shadeDefault, "ffeb3b"],
  ];

  //Colors for theme
  static Color lightPrimary = const Color(0xfffcfcff);
  static Color darkPrimary = Colors.black;
  static Color lightAccent = Colors.blue;
  static Color darkAccent = Colors.blueAccent;
  static Color lightBG = const Color(0xfffcfcff);
  static Color darkBG = Colors.black;

  static String nomicsKey = "401d022aaa72eaf9855467c267d7598391561d8e";

  static ThemeData lightTheme = ThemeData(
    backgroundColor: lightBG,
    primaryColorLight: darkBG,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBG,
    appBarTheme: AppBarTheme(
      elevation: 0,
      toolbarTextStyle: TextStyle(
        color: darkBG,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: lightAccent),
    textSelectionTheme: TextSelectionThemeData(cursorColor: lightAccent),
  );

  static ThemeData darkTheme = ThemeData(
    backgroundColor: darkBG,
    primaryColorLight: lightBG,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBG,
    appBarTheme: AppBarTheme(
      elevation: 0,
      toolbarTextStyle: TextStyle(
        color: lightBG,
        fontSize: 18.0,
        fontWeight: FontWeight.w800,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch()
        .copyWith(secondary: darkAccent, brightness: Brightness.dark),
    textSelectionTheme: TextSelectionThemeData(cursorColor: darkAccent),
  );
}
