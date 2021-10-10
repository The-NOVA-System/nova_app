import 'dart:math';
import 'package:nova_system/util/const.dart';
import 'package:nova_system/util/data.dart';
import 'package:nova_system/widgets/wallet.dart';
import 'package:flutter/material.dart';

class Wallets extends StatefulWidget {
  const Wallets({Key? key}) : super(key: key);

  @override
  _WalletsState createState() => _WalletsState();
}

class _WalletsState extends State<Wallets> {
  var color = Constants.matColors[Random().nextInt(Constants.matColors.length)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          primary: false,
          itemCount: coins.length,
          itemBuilder: (BuildContext context, int index) {
            Map coin = coins[index];

            return Wallet(
              name: coin['name'],
              icon: coin['icon'],
              rate: coin['rate'],
              color: color[0],
              alt: coin['alt'],
              colorHex: color[1]
            );
          },
        ),
        onRefresh: () {
          return Future.delayed(
              const Duration(seconds: 0),
                  () {
                setState(() {
                  Config.chartRefresh();
                });
              }
          );
        },
      ),
    );
  }
}
