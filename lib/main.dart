import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:nova/screens/home.dart';
import 'package:nova/screens/landing_page.dart';
import 'package:nova/utils/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: AppThemes.lightTheme,
      dark: AppThemes.darkTheme,
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'The Nova System',
        theme: theme,
        darkTheme: darkTheme,
        home: const AuthGate(),
      ),
    );
  }
}
