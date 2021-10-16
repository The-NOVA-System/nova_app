import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:nova_system/screens/buyandsell.dart';
import 'package:nova_system/screens/transactions.dart';
import 'package:nova_system/screens/wallets.dart';
import 'package:nova_system/widgets/wallet.dart';
import 'package:nova_system/util/data.dart';
import 'package:flutter/material.dart';

enum Section { logOut, home }
Section section = Section.home;

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  String name = names;

  @override
  Widget build(BuildContext context) {
    Widget home = Scaffold(
      appBar: AppBar(
          leading: InkWell(
              onTap: () {
                _key.currentState!.openDrawer();
              },
              child: Icon(Icons.menu,
                  color:
                      Theme.of(context).appBarTheme.toolbarTextStyle!.color)),
          actions: const <Widget>[],
          backgroundColor: Theme.of(context).primaryColor),
      key: _key,
      drawer: Theme(
        data: Theme.of(context)
            .copyWith(canvasColor: Theme.of(context).primaryColor),
        child: Drawer(
          // Add a ListView to the drawer. This ensures the user can scroll
          // through the options in the drawer if there isn't enough vertical
          // space to fit everything.
          child: ListView(
            cacheExtent: 12,
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: <Widget>[
              SizedBox(
                child: DrawerHeader(
                  child: Container(
                    child: const Text("Options"),
                    alignment: Alignment.topCenter, // <-- ALIGNMENT
                    height: 10,
                  ),
                  decoration:
                      BoxDecoration(color: Theme.of(context).primaryColor),
                ),
                height: 50, // <-- HEIGHT
              ),
              ListTile(
                title: Text("Theme: " +
                    EasyDynamicTheme.of(context)
                        .themeMode
                        .toString()
                        .split(".")[1]
                        .capitalize()),
                onTap: () {
                  EasyDynamicTheme.of(context).changeTheme();
                },
              ),
              ListTile(
                title: const Text('Logout'),
                onTap: () {
                  setState(() => section = Section.logOut);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: <Widget>[
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage(
                  "assets/${name.toLowerCase().replaceAll(" ", "_")}.png",
                ),
                radius: 25,
              ),
              title: Text(name),
              subtitle: Text(email),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.center,
              child: DefaultTabController(
                length: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TabBar(
                      isScrollable: false,
                      labelColor: Theme.of(context).colorScheme.secondary,
                      unselectedLabelColor:
                          Theme.of(context).textTheme.caption!.color,
                      tabs: const <Widget>[
                        Tab(
                          text: "Wallets",
                        ),
                        Tab(
                          text: "Transactions",
                        ),
                        Tab(
                          text: "Buy/Sell",
                        ),
                      ],
                      onTap: (index) {
                        setState(() {
                          page = 0;
                          Config.chartRefresh();
                        });
                      },
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      height: 225.0 * length,
                      child: const TabBarView(
                        children: <Widget>[
                          Wallets(),
                          Transactions(),
                          BuyandSell(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    ),
    );

    Widget logOut = Scaffold(
      appBar: AppBar(
          leading: InkWell(
              onTap: () {
                setState(() => section = Section.home);
                Config.chartRefresh();
              },
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color:
                      Theme.of(context).appBarTheme.toolbarTextStyle!.color)),
          backgroundColor: Theme.of(context).primaryColor),
      body: const Center(
        child: Text(
          'This is a new screen',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );

    Widget body;

    switch (section) {
      case Section.home:
        body = home;
        break;

      case Section.logOut:
        body = logOut;
        break;
    }

    return Scaffold(
      body: Container(
        child: body,
      ),
    );
  }
}
