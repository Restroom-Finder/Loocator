import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:loocator/constants.dart';
import 'package:loocator/pages/profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return FirebaseAuth.instance.currentUser != null
        ? const ProfilePage()
        : Scaffold(
            appBar: AppBar(
              title: const Text('Loocator'),
            ),
            body: SignInScreen(
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  Navigator.pop(context);
                  showMessage("${FirebaseAuth.instance.currentUser}");
                  // Defauly display name is the first section of the user's email
                  FirebaseAuth.instance.currentUser!.updateDisplayName(
                      FirebaseAuth.instance.currentUser!.email!.split('@')[0]);
                }),
              ],
            ),
          );
  }

  void showMessage(String message) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
