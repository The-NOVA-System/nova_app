import 'package:flutter/material.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSwatch()
          .copyWith(primary: Colors.grey.shade300, secondary: Colors.indigo));

  static ThemeData darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSwatch()
          .copyWith(primary: Colors.grey.shade600, secondary: Colors.indigo));
}
