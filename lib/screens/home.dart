import "dart:math";

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:nova/screens/wallets.dart' as wallets;
import 'package:nova/screens/leaderboard.dart';
import 'package:nova/screens/buy.dart' as buy;
import 'package:nova/widgets/wallet.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tab_indicator_styler/tab_indicator_styler.dart';
import 'package:http/http.dart' as http;
import 'package:webfeed/webfeed.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final beforeNonLeadingCapitalLetter = RegExp(r"(?=(?!^)[A-Z])");
List<String> splitPascalCase(String input) =>
    input.split(beforeNonLeadingCapitalLetter);

enum Section { about, home, blog }
Section section = Section.home;

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

http.Client client = http.Client();

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  @override
  void dispose() {
    client.close();
    super.dispose();
  }

  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference global = FirebaseFirestore.instance.collection('global');
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  String name = FirebaseAuth.instance.currentUser!.email!.split("@")[0];
  TabController? controller;

  @override
  void initState() {
    client = http.Client();
    super.initState();
    controller = TabController(length: 3, vsync: this);
  }

  refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget home = DefaultTabController(
      length: 3,
      child: Scaffold(
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
                  title: const Text('About'),
                  onTap: () {
                    setState(() => section = Section.about);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('GitHub'),
                  onTap: () {
                    launch('https://github.com/The-NOVA-System');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Blog'),
                  onTap: () {
                    setState(() => section = Section.blog);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Logout'),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.pop(context);
                  },
                ),
                FutureBuilder<DocumentSnapshot>(
                  future: global.doc('coffee').get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Text("Something went wrong");
                    }

                    if (snapshot.hasData && !snapshot.data!.exists) {
                      return const Text("Document does not exist");
                    }

                    if (snapshot.connectionState == ConnectionState.done) {
                      Map<String, dynamic> data =
                          snapshot.data!.data() as Map<String, dynamic>;

                      if (data['active'] == true) {
                        return ListTile(
                          title: const Text('Buy Me A Coffee'),
                          onTap: () {
                            launch(data['link']);
                            Navigator.pop(context);
                          },
                        );
                      } else {
                        return const ListTile(
                          title: Text(''),
                        );
                      }
                    }

                    return const ListTile(
                      title: Text('Loading...'),
                    );
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
                  background: MediaQuery(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(15, 0, 30, 0),
                          leading: ClipOval(
                              child: SvgPicture.network(
                            'https://avatars.dicebear.com/api/avataaars/${FirebaseAuth.instance.currentUser!.email!.split("@")[0]}.svg',
                            width: 50,
                            height: 50,
                            semanticsLabel: 'profile picture',
                            placeholderBuilder: (BuildContext context) =>
                                Container(
                                    padding: const EdgeInsets.all(30.0),
                                    child: const CircularProgressIndicator()),
                          )),
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(FirebaseAuth.instance.currentUser!.email!),
                              FutureBuilder<DocumentSnapshot>(
                                future: users
                                    .doc(FirebaseAuth.instance.currentUser!.uid)
                                    .get(),
                                builder: (BuildContext context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
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
                                        "Balance: ${data['USD'].toStringAsFixed(3)} USD");
                                  }

                                  return const Text("Balance: Loading...");
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                  ),
                ),
                expandedHeight: 125.0,
                bottom: TabBar(
                  indicator: MaterialIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  isScrollable: false,
                  labelColor: Theme.of(context).colorScheme.secondary,
                  unselectedLabelColor:
                      Theme.of(context).textTheme.caption!.color,
                  tabs: const <Widget>[
                    Tab(
                      text: "Wallets",
                    ),
                    Tab(
                      text: "Leaderboard",
                    ),
                    Tab(
                      text: "Buy",
                    ),
                  ],
                  onTap: (index) {
                    if (index == 0) {
                      setState(() {
                        buy.counter = 1;
                        wallets.counter = 1;
                        buy.page = 1.0;
                        wallets.page = 1.0;
                        Config.chartRefresh();
                      });
                    }
                  },
                  controller: controller,
                ),
              )
            ];
          },
          body: FutureBuilder<DocumentSnapshot>(
              future: global.doc('api-keys').get(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  Map<String, dynamic> data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  if (kIsWeb) {
                    return TabBarView(
                      controller: controller,
                      children: <Widget>[
                        wallets.Wallets(
                          notifyParent: refresh,
                          nomicsApi: data['web'],
                        ),
                        leaderboard(
                          nomicsApi: data['web'],
                        ),
                        buy.Buy(
                            notifyParent: refresh,
                          nomicsApi: data['web'],
                        ),
                      ],
                    );
                  } else {
                    final _random = Random();

                    return TabBarView(
                      controller: controller,
                      children: <Widget>[
                        wallets.Wallets(
                          notifyParent: refresh,
                          nomicsApi: data['local'][_random.nextInt(data['local'].length)],
                        ),
                        leaderboard(
                          nomicsApi: data['local'][_random.nextInt(data['local'].length)],
                        ),
                        buy.Buy(
                          notifyParent: refresh,
                          nomicsApi: data['local'][_random.nextInt(data['local'].length)],
                        ),
                      ],
                    );
                  }
                } else {
                  return const Center(
                    child: SizedBox(
                      height: 25.0,
                      width: 25.0,
                      child: Align(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
              }),
        ),
      ),
    );

    Widget about = Scaffold(
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
      body: Center(
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Created by Garv Shah\n',
                style: TextStyle(
                    color:
                        Theme.of(context).appBarTheme.toolbarTextStyle!.color),
              ),
              TextSpan(
                text:
                    'Crypto Market Cap & Pricing Data Provided By Nomics.\n\n',
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launch('https://nomics.com/');
                  },
              ),
              TextSpan(
                text:
                    'Big thanks to the rest of The NOVA Team:\nLiam Shaw\nNatsuki Rogers\n\n',
                style: TextStyle(
                    color:
                        Theme.of(context).appBarTheme.toolbarTextStyle!.color),
              ),
              TextSpan(
                text: 'https://garv-shah.github.io',
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    launch('https://garv-shah.github.io');
                  },
              ),
            ],
          ),
        ),
      ),
    );

    Widget blog = Scaffold(
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
      body: FutureBuilder<Response>(
        future: http
            .get(Uri.parse('https://the-nova-system.github.io/blog/feed.xml')),
        builder: (BuildContext context, AsyncSnapshot<Response> snapshot) {
          if (snapshot.hasError) {
            return const Text("Something went wrong");
          }

          if (snapshot.connectionState == ConnectionState.done) {
            var atomFeed = AtomFeed.parse(snapshot.data!.body.toString());
            double width = MediaQuery.of(context).size.width;
            var inputFormat = DateFormat('dd/MM/yyyy');

            return Scaffold(
              body: ListView.builder(
                  shrinkWrap: true,
                  cacheExtent: 9999,
                  physics: const AlwaysScrollableScrollPhysics(),
                  primary: false,
                  itemCount: atomFeed.items!.length + 2,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return Center(
                          child: Text(
                        atomFeed.title!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.08,
                        ),
                      ));
                    } else if (index == 1) {
                      return const SizedBox(height: 20);
                    }
                    return SizedBox(
                      width: 20.0,
                      height: 240.0,
                      child: Card(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                atomFeed.items![index - 2].title!,
                                style: TextStyle(
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.normal, //
                                  // regular weight
                                  color: (() {
                                    if (Theme.of(context).brightness ==
                                        Brightness.light) {
                                      return Colors.grey.shade800;
                                    } else {
                                      return Colors.white;
                                    }
                                  }()),
                                  fontSize: 18.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "By ${atomFeed.items![index - 2].authors!.first.name!} - ${inputFormat.format(atomFeed.items![index - 2].updated!)}",
                                style: TextStyle(
                                    fontStyle: FontStyle.normal,
                                    fontWeight:
                                        FontWeight.normal, // regular weight
                                    color: (() {
                                      if (Theme.of(context).brightness ==
                                          Brightness.light) {
                                        return Colors.grey.shade600;
                                      } else {
                                        return Colors.white70;
                                      }
                                    }()),
                                    fontSize: 14.0),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                atomFeed.items![index - 2].summary!,
                                style: TextStyle(
                                    fontStyle: FontStyle.normal,
                                    fontWeight:
                                        FontWeight.normal, // regular weight
                                    color: (() {
                                      if (Theme.of(context).brightness ==
                                          Brightness.light) {
                                        return Colors.grey.shade700;
                                      } else {
                                        return Colors.white54;
                                      }
                                    }()),
                                    fontSize: 16.0),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Read More',
                                      style:
                                          const TextStyle(color: Colors.blue),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          launch(atomFeed.items![index - 2]
                                              .links!.first.href!);
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
            );
          }

          return const Center(
            child: SizedBox(
              height: 25.0,
              width: 25.0,
              child: Align(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              ),
            ),
          );
        },
      ),
    );

    Widget body;

    switch (section) {
      case Section.home:
        body = home;
        break;

      case Section.about:
        body = about;
        break;

      case Section.blog:
        body = blog;
        break;
    }

    return Scaffold(
      body: Container(
        child: body,
      ),
    );
  }
}
