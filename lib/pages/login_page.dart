import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:loocator/constants.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser != null
        ? Scaffold(
            appBar: AppBar(
              title: const Text('Log In'),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text('Loocator'),
            ),
            body: SignInScreen(
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  showMessage('Logged In');
                })
              ],
            ),
          );
  }

  void showMessage(String message) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
