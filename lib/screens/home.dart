import "dart:math";

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_dynamic_theme/easy_dynamic_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:nova/screens/landing_page.dart';
import 'package:nova/screens/register_page.dart';
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
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:mime/mime.dart';
import 'dart:io' show Platform;
import 'package:file_selector/file_selector.dart';
import 'package:nova/util/buy_me_a_coffee/buy_me_a_coffee_widget.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:nova/util/contactus.dart';

firebase_storage.FirebaseStorage storage =
    firebase_storage.FirebaseStorage.instance;

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

  Widget profile = const SizedBox(
      width: 50,
      height: 50,
      child: Center(
          child: SizedBox(
              width: 25, height: 25, child: CircularProgressIndicator())));

  bool profileSet = false;

  CollectionReference users = FirebaseFirestore.instance.collection('users');
  CollectionReference global = FirebaseFirestore.instance.collection('global');
  final GlobalKey<ScaffoldState> _key = GlobalKey();

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
    Widget about = Scaffold(
      appBar: AppBar(
          leading: InkWell(
              onTap: () {
                Navigator.pop(context);
                Config.chartRefresh();
              },
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color:
                      Theme.of(context).appBarTheme.toolbarTextStyle!.color)),
          backgroundColor: Theme.of(context).primaryColor),
      body: Center(
        child: ListView(
          children: [
            ContactUs(
              avatarPadding: 30.0,
              cardColor: Colors.white,
              textColor: Colors.black,
              logo: const AssetImage('assets/images/garv.jpg'),
              avatarRadius: 100,
              email: 'gshah.6110@gmail.com',
              companyName: 'Garv Shah',
              companyColor: Theme.of(context).appBarTheme.toolbarTextStyle!.color!,
              dividerThickness: 2,
              dividerColor: Colors.grey,
              website: 'https://garv-shah.github.io',
              githubUserName: 'garv-shah',
              tagLine: 'Developer & Student',
              taglineColor: Theme.of(context).appBarTheme.toolbarTextStyle!.color!,
            ),
            const SizedBox(height: 25),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text:
                        'Crypto Market Cap & Pricing Data Provided By Nomics.\n\n',
                    style: const TextStyle(color: Colors.blue),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launch('https://nomics.com/');
                      },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Widget blog = Scaffold(
      appBar: AppBar(
          leading: InkWell(
              onTap: () {
                Navigator.pop(context);
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
            child: Column(
              mainAxisSize: MainAxisSize.max,
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
                    Navigator.pop(context);
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => about));
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
                    Navigator.pop(context);
                    Navigator.push(
                        context, MaterialPageRoute(builder: (_) => blog));
                  },
                ),
                ListTile(
                  title: const Text('Logout'),
                  onTap: () {
                    FirebaseAuth.instance.signOut();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LandingPage()),
                    );
                  },
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: global.doc('coffee').get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return const Text("Something went wrong");
                          }

                          if (snapshot.hasData && !snapshot.data!.exists) {
                            return const Text("Document does not exist");
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            Map<String, dynamic> data =
                                snapshot.data!.data() as Map<String, dynamic>;

                            if (data['active'] == true) {
                              return BuyMeACoffeeWidget(
                                customText: data['text'],
                                sponsorID: "nova.system",
                                theme: OrangeTheme(),
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
                    ),
                  ),
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
                pinned: true,
                backgroundColor: Theme.of(context).backgroundColor,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    ListTile(
                      contentPadding: const EdgeInsets.fromLTRB(15, 0, 30, 0),
                      leading: InkWell(
                        customBorder: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        onTap: () async {
                          if (kIsWeb) {
                            final XFile? profileImage = await ImagePicker()
                                .pickImage(source: ImageSource.gallery);
                            var bytes = await profileImage!.readAsBytes();

                            if (userData['superNova'] == false) {
                              if (lookupMimeType('', headerBytes: bytes) ==
                                  'image/gif') {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Sorry!'),
                                        content: const Text(
                                            "Animated profile pictures are only available for Super NOVA users."),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    });
                              } else {
                                setState(() {
                                  profile = CircleAvatar(
                                    backgroundImage: MemoryImage(bytes),
                                    radius: 25,
                                  );
                                });
                                if (userData['profileType'] != "") {
                                  await storage
                                      .ref(
                                          'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                      .delete();
                                }
                                firebase_storage.Reference ref = firebase_storage
                                    .FirebaseStorage.instance
                                    .ref(
                                        'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                                firebase_storage.SettableMetadata metadata =
                                    firebase_storage.SettableMetadata(
                                        contentType: lookupMimeType('',
                                            headerBytes: bytes));

                                await ref.putData(bytes, metadata);
                                await fireStoreUserRef.update({
                                  'defaultProfile': false,
                                  'profileType':
                                      lookupMimeType('', headerBytes: bytes)
                                });
                                await global.doc('cached-urls').set(
                                  {
                                    FirebaseAuth.instance.currentUser!.email!.split("@")[0]: await ref.getDownloadURL(),
                                  },
                                  SetOptions(merge: true),
                                );
                              }
                            } else {
                              setState(() {
                                profile = CircleAvatar(
                                  backgroundImage: MemoryImage(bytes),
                                  radius: 25,
                                );
                              });
                              if (userData['profileType'] != "") {
                                await storage
                                    .ref(
                                        'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                    .delete();
                              }
                              firebase_storage.Reference ref =
                                  firebase_storage.FirebaseStorage.instance.ref(
                                      'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                              firebase_storage.SettableMetadata metadata =
                                  firebase_storage.SettableMetadata(
                                      contentType: lookupMimeType('',
                                          headerBytes: bytes));

                              await ref.putData(bytes, metadata);
                              await fireStoreUserRef.update({
                                'defaultProfile': false,
                                'profileType':
                                    lookupMimeType('', headerBytes: bytes)
                              });
                              await global.doc('cached-urls').set(
                                {
                                  FirebaseAuth.instance.currentUser!.email!.split("@")[0]: await ref.getDownloadURL(),
                                },
                                SetOptions(merge: true),
                              );
                            }
                          } else if (Platform.isMacOS) {
                            XTypeGroup typeGroup;
                            if (userData['superNova'] == true) {
                              typeGroup = XTypeGroup(
                                  label: 'images',
                                  extensions: ['jpg', 'png', 'gif', 'jpeg']);
                            } else {
                              typeGroup = XTypeGroup(
                                  label: 'images',
                                  extensions: ['jpg', 'png', 'jpeg']);
                            }

                            final XFile? profileImage =
                                await openFile(acceptedTypeGroups: [typeGroup]);
                            var bytes = await profileImage!.readAsBytes();
                            setState(() {
                              profile = CircleAvatar(
                                backgroundImage: MemoryImage(bytes),
                                radius: 25,
                              );
                            });
                            if (userData['profileType'] != "") {
                              await storage
                                  .ref(
                                      'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                  .delete();
                            }
                            firebase_storage.Reference ref =
                                firebase_storage.FirebaseStorage.instance.ref(
                                    'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                            firebase_storage.SettableMetadata metadata =
                                firebase_storage.SettableMetadata(
                                    contentType:
                                        lookupMimeType('', headerBytes: bytes));

                            await ref.putData(bytes, metadata);
                            await fireStoreUserRef.update({
                              'defaultProfile': false,
                              'profileType':
                                  lookupMimeType('', headerBytes: bytes)
                            });
                            await global.doc('cached-urls').set(
                              {
                                FirebaseAuth.instance.currentUser!.email!.split("@")[0]: await ref.getDownloadURL(),
                              },
                              SetOptions(merge: true),
                            );
                          } else {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return SimpleDialog(
                                      title:
                                          const Text("Change Profile Picture"),
                                      children: <Widget>[
                                        SimpleDialogOption(
                                          onPressed: () async {
                                            final XFile? profileImage =
                                                await ImagePicker().pickImage(
                                                    source:
                                                        ImageSource.gallery);
                                            var bytes = await profileImage!
                                                .readAsBytes();
                                            setState(() {
                                              profile = CircleAvatar(
                                                backgroundImage:
                                                    MemoryImage(bytes),
                                                radius: 25,
                                              );
                                            });

                                            Navigator.pop(context);
                                            if (userData['profileType'] != "") {
                                              await storage
                                                  .ref(
                                                      'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                                  .delete();
                                            }
                                            firebase_storage.Reference ref =
                                                firebase_storage
                                                    .FirebaseStorage.instance
                                                    .ref(
                                                        'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                                            firebase_storage.SettableMetadata
                                                metadata = firebase_storage
                                                    .SettableMetadata(
                                                        contentType:
                                                            lookupMimeType(
                                                                '',
                                                                headerBytes:
                                                                    bytes));

                                            await ref.putData(bytes, metadata);
                                            await fireStoreUserRef.update({
                                              'defaultProfile': false,
                                              'profileType': lookupMimeType('',
                                                  headerBytes: bytes)
                                            });
                                            await global.doc('cached-urls').set(
                                              {
                                                FirebaseAuth.instance.currentUser!.email!.split("@")[0]: await ref.getDownloadURL(),
                                              },
                                              SetOptions(merge: true),
                                            );
                                          },
                                          child:
                                              const Text('Pick From Gallery'),
                                        ),
                                        SimpleDialogOption(
                                          onPressed: () async {
                                            final XFile? profileImage =
                                                await ImagePicker().pickImage(
                                                    source: ImageSource.camera);
                                            var bytes = await profileImage!
                                                .readAsBytes();
                                            setState(() {
                                              profile = CircleAvatar(
                                                backgroundImage:
                                                    MemoryImage(bytes),
                                                radius: 25,
                                              );
                                            });

                                            Navigator.pop(context);
                                            if (userData['profileType'] != "") {
                                              await storage
                                                  .ref(
                                                      'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${userData['profileType'].split('/')[1]}')
                                                  .delete();
                                            }
                                            firebase_storage.Reference ref =
                                                firebase_storage
                                                    .FirebaseStorage.instance
                                                    .ref(
                                                        'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${lookupMimeType('', headerBytes: bytes)!.split('/')[1]}');

                                            firebase_storage.SettableMetadata
                                                metadata = firebase_storage
                                                    .SettableMetadata(
                                                        contentType:
                                                            lookupMimeType(
                                                                '',
                                                                headerBytes:
                                                                    bytes));

                                            await ref.putData(bytes, metadata);
                                            await fireStoreUserRef.update({
                                              'defaultProfile': false,
                                              'profileType': lookupMimeType('',
                                                  headerBytes: bytes)
                                            });
                                            await global.doc('cached-urls').set(
                                              {
                                                FirebaseAuth.instance.currentUser!.email!.split("@")[0]: await ref.getDownloadURL(),
                                              },
                                              SetOptions(merge: true),
                                            );
                                          },
                                          child:
                                              const Text('Take A New Picture'),
                                        ),
                                      ]);
                                });
                          }
                        },
                        child: profile,
                      ),
                      title: FutureBuilder<DocumentSnapshot>(
                        future: users
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.hasError) {
                            return const Text("Something went wrong");
                          }

                          if (snapshot.hasData && !snapshot.data!.exists) {
                            return const Text("Document does not exist");
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            Map<String, dynamic> data =
                                snapshot.data!.data() as Map<String, dynamic>;

                            userData = data;

                            WidgetsBinding.instance!.addPostFrameCallback((_) =>
                                Future.delayed(const Duration(milliseconds: 0),
                                    () {
                                  if (profileSet == false) {
                                    if (data['defaultProfile'] == false) {
                                      firebase_storage.Reference ref =
                                          firebase_storage
                                              .FirebaseStorage.instance
                                              .ref(
                                                  'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${data['profileType'].split('/')[1]}');
                                      ref.getDownloadURL().then((value) => {
                                            setState(() {
                                              profile = ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: value,
                                                  fit: BoxFit.fill,
                                                  width: 50,
                                                  height: 50,
                                                  placeholder: (context, url) =>
                                                      const SizedBox(
                                                          height: 50,
                                                          width: 50,
                                                          child:
                                                              CircularProgressIndicator()),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          const SizedBox(
                                                              height: 50,
                                                              width: 50,
                                                              child: Icon(
                                                                  Icons.error)),
                                                ),
                                              );
                                              profileSet = true;
                                            })
                                          });
                                    } else {
                                      setState(() {
                                        profile = ClipOval(
                                            child: SvgPicture.network(
                                          'https://avatars.dicebear.com/api/avataaars/${FirebaseAuth.instance.currentUser!.email!.split("@")[0]}.svg',
                                          width: 50,
                                          height: 50,
                                          semanticsLabel: 'profile picture',
                                          placeholderBuilder: (BuildContext
                                                  context) =>
                                              const SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child:
                                                      CircularProgressIndicator()),
                                        ));
                                        profileSet = true;
                                      });
                                    }
                                  }
                                }));

                            return GestureDetector(
                              onTap: () async {
                                final username = await showTextInputDialog(
                                  style: AdaptiveStyle.material,
                                  context: context,
                                  textFields: [
                                    DialogTextField(
                                      hintText: 'username',
                                      validator: (value) => value!.isEmpty
                                          ? "username can't be empty"
                                          : null,
                                    ),
                                  ],
                                  title: 'Change Username',
                                  autoSubmit: true,
                                );

                                if (username != null) {
                                  await fireStoreUserRef.update({
                                    'username': username[0]
                                  });
                                  setState(() {});
                                }
                              },
                              child: Text(data["username"]),
                            );
                          }

                          return const Text("Loading...");
                        },
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Text(
                                  FirebaseAuth.instance.currentUser!.email!)),
                          FittedBox(
                            fit: BoxFit.fitWidth,
                            child: FutureBuilder<DocumentSnapshot>(
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const RegisterPage()),
                                  );
                                  return const Text("Document does not exist");
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  Map<String, dynamic> data = snapshot.data!
                                      .data() as Map<String, dynamic>;

                                  userData = data;

                                  WidgetsBinding.instance!.addPostFrameCallback(
                                      (_) => Future.delayed(
                                              const Duration(milliseconds: 0),
                                              () {
                                            if (profileSet == false) {
                                              if (data['defaultProfile'] ==
                                                  false) {
                                                firebase_storage.Reference ref =
                                                    firebase_storage
                                                        .FirebaseStorage
                                                        .instance
                                                        .ref(
                                                            'profiles/${FirebaseAuth.instance.currentUser!.uid}/profile.${data['profileType'].split('/')[1]}');
                                                ref
                                                    .getDownloadURL()
                                                    .then((value) => {
                                                          setState(() {
                                                            profile = ClipOval(
                                                              child:
                                                                  CachedNetworkImage(
                                                                imageUrl: value,
                                                                fit:
                                                                    BoxFit.fill,
                                                                width: 50,
                                                                height: 50,
                                                                placeholder: (context,
                                                                        url) =>
                                                                    const SizedBox(
                                                                        height:
                                                                            50,
                                                                        width:
                                                                            50,
                                                                        child:
                                                                            CircularProgressIndicator()),
                                                                errorWidget: (context,
                                                                        url,
                                                                        error) =>
                                                                    const SizedBox(
                                                                        height:
                                                                            50,
                                                                        width:
                                                                            50,
                                                                        child: Icon(
                                                                            Icons.error)),
                                                              ),
                                                            );
                                                            profileSet = true;
                                                          })
                                                        });
                                              } else {
                                                setState(() {
                                                  profile = ClipOval(
                                                      child: SvgPicture.network(
                                                    'https://avatars.dicebear.com/api/avataaars/${FirebaseAuth.instance.currentUser!.email!.split("@")[0]}.svg',
                                                    width: 50,
                                                    height: 50,
                                                    semanticsLabel:
                                                        'profile picture',
                                                    placeholderBuilder:
                                                        (BuildContext
                                                                context) =>
                                                            const SizedBox(
                                                                height: 50,
                                                                width: 50,
                                                                child:
                                                                    CircularProgressIndicator()),
                                                  ));
                                                  profileSet = true;
                                                });
                                              }
                                            }
                                          }));

                                  return Text(
                                      "Balance: ${data['USD'].toStringAsFixed(3)} USD");
                                }

                                return const Text("Balance: Loading...");
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                expandedHeight: 70,
                collapsedHeight: 70,
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
                    } else {
                      buy.counter = 1;
                      wallets.counter = 1;
                      buy.page = 1.0;
                      wallets.page = 1.0;
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
                          notifyParent: refresh,
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
                          nomicsApi: data['local']
                              [_random.nextInt(data['local'].length)],
                        ),
                        leaderboard(
                          notifyParent: refresh,
                          nomicsApi: data['local']
                              [_random.nextInt(data['local'].length)],
                        ),
                        buy.Buy(
                          notifyParent: refresh,
                          nomicsApi: data['local']
                              [_random.nextInt(data['local'].length)],
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
