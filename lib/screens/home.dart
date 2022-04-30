import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            AdaptiveTheme.of(context).toggleThemeMode();
          },
          child: const Icon(Icons.accessibility)
      ),
      appBar: AppBar(
        title: const Text('Homepage'),
      ),
      body: const Center(
        child: Text('Hello World'),
      ),
    );
  }
}