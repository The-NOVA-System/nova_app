import 'package:nova/util/const.dart';
import 'package:nova/widgets/custom_btn.dart';
import 'package:nova/widgets/custom_input.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  CollectionReference users = FirebaseFirestore.instance.collection('users');
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  // Build an alert dialog to display some errors.
  Future<void> _alertDialogBuilder(String error) async {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(error),
            actions: [
              TextButton(
                child: const Text("Close Dialog"),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }

  // Create a new user account
  String? _createAccount() {
    if (_registerUsername == "") {
      return "username must not be empty";
    } else {
      return null;
    }
  }

  void _submitForm() async {
    // Set the form to loading state
    setState(() {
      _registerFormLoading = true;
    });

    // Run the create account method
    String? _createAccountFeedback = _createAccount();

    // If the string is not null, we got error while create account.
    if (_createAccountFeedback != null) {
      _alertDialogBuilder(_createAccountFeedback);

      // Set the form to regular state [not loading].
      setState(() {
        _registerFormLoading = false;
      });
    } else {
      // The String was null, user is logged in.
      users
          .doc(FirebaseAuth.instance.currentUser!.uid).set({
        'email': FirebaseAuth.instance.currentUser!.email,
        'USD': 100,
        'assets': [],
        'badges': [],
        'defaultProfile': true,
        'profileType': '',
        'superNova': false,
        'username': _registerUsername
      })
          .then((value) => print("User Added"))
          .catchError((error) => print("Failed to add user: $error"));
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const Home()),
      );
    }
  }

  // Default Form Loading State
  bool _registerFormLoading = false;

  // Form Input Field Values
  String _registerUsername = "";

  // Focus Node for input fields
  late FocusNode _passwordFocusNode;
  late FocusNode _emailFocusNode;

  @override
  void initState() {
    _passwordFocusNode = FocusNode();
    _emailFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF404e8f), Color(0xFF011569)])),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                  ),
                  child: const Text(
                    "Enter Username",
                    textAlign: TextAlign.center,
                    style: Constants.boldHeading,
                  ),
                ),
                const SizedBox(height: 15),
                AutofillGroup(
                  child: Column(
                    children: [
                      CustomInput(
                        hintText: "Username...",
                        onChanged: (value) {
                          _registerUsername = value;
                        },
                        isPasswordField: false,
                        onSubmitted: (value) {
                          _submitForm();
                        },
                      ),
                      CustomBtn(
                        text: "Create New Account",
                        onPressed: () {
                          _submitForm();
                        },
                        isLoading: _registerFormLoading,
                      )
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 16.0,
                  ),
                  child: Text(""),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
