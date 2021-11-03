import 'package:nova/util/const.dart';
import 'package:nova/widgets/custom_btn.dart';
import 'package:nova/screens/confirm_email.dart';
import 'package:nova/widgets/custom_input.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);
  static String id = 'forgot-password';
  final String message =
      "An email has just been sent to you, Click the link provided to complete password reset";

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _auth = FirebaseAuth.instance;
  late String _email;

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
  _passwordReset() async {
    try {
      final user = await _auth.sendPasswordResetEmail(email: _email);

      showDialog<void>(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sent!'),
            content: SingleChildScrollView(
              child: Text(widget.message),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('great!'),
                onPressed: () {
                  var nav = Navigator.of(context);
                  nav.pop();
                  nav.pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print(e);
    }
  }

  // Default Form Loading State
  bool _registerFormLoading = false;

  // Focus Node for input fields
  late FocusNode _passwordFocusNode;

  @override
  void initState() {
    _passwordFocusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _passwordFocusNode.dispose();
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 24.0,
                  ),
                  child: const Text(
                    "Reset Your Password",
                    textAlign: TextAlign.center,
                    style: Constants.boldHeading,
                  ),
                ),
                AutofillGroup(
                  child: Column(
                    children: [
                      CustomInput(
                        hintText: "Email...",
                        onChanged: (value) {
                          _email = value;
                        },
                        onSubmitted: (value) {
                          _passwordFocusNode.requestFocus();
                        },
                        textInputAction: TextInputAction.next,
                        autoFillHints: const [AutofillHints.newUsername],
                      ),
                      CustomBtn(
                        text: "Reset",
                        onPressed: () {
                          _passwordReset();
                        },
                        isLoading: _registerFormLoading,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16.0,
                  ),
                  child: CustomBtn(
                    text: "Back To Login",
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    outlineBtn: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
