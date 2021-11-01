import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nova/screens/buyandsell.dart';
import 'package:nova/screens/transactions.dart';
import 'package:nova/screens/wallets.dart';
import 'package:nova/widgets/wallet.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final beforeNonLeadingCapitalLetter = RegExp(r"(?=(?!^)[A-Z])");
List<String> splitPascalCase(String input) =>
    input.split(beforeNonLeadingCapitalLetter);

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

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  String name = FirebaseAuth.instance.currentUser!.email!.split("@")[0];
  TabController? controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
  }

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
                  FirebaseAuth.instance.signOut();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              automaticallyImplyLeading: false,
              pinned: false,
              backgroundColor: Theme.of(context).backgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                        leading: ClipOval(
                            child: SvgPicture.network(
                          'https://avatars.dicebear.com/api/avataaars/${FirebaseAuth.instance.currentUser!.email!.split("@")[0]}.svg',
                          width: 50,
                          height: 50,
                          semanticsLabel: 'profile picture',
                          placeholderBuilder: (BuildContext context) => Container(
                              padding: const EdgeInsets.all(30.0),
                              child: const CircularProgressIndicator()),
                        )),
                      title: Text(name),
                      subtitle: Text(FirebaseAuth.instance.currentUser!.email!),
                    ),
                  ],
                ),
              ),
              expandedHeight: 125.0,
              bottom: TabBar(
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
                  if (index == 0) {
                    setState(() {
                      page = 1.0;
                      Config.chartRefresh();
                    });
                  }
                },
                controller: controller,
              ),
            )
          ];
        },
        body: TabBarView(
          controller: controller,
          children: const <Widget>[
            Wallets(),
            Transactions(),
            BuyandSell(),
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
