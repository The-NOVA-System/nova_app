import 'package:flutter/material.dart';


class Wallets extends StatefulWidget {
  const Wallets({Key? key}) : super(key: key);

  @override
  _WalletsState createState() => _WalletsState();
}

class _WalletsState extends State<Wallets> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text("You have no assets yet!")),
    );
  }
}
