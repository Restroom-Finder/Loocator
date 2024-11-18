import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
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
              backgroundColor: Theme.of(context).primaryColorLight,
            ),
            body: SignInScreen(
              actions: [
                AuthStateChangeAction<SignedIn>((context, state) {
                  Navigator.pop(context);
                  showMessage("Signed In.");
                }),
                AuthStateChangeAction<UserCreated>((context, state) {
                  // Default display name is the first section of the user's email
                  FirebaseAuth.instance.currentUser!.updateDisplayName(
                      FirebaseAuth.instance.currentUser!.email!.split('@')[0]);
                  FirebaseAuth.instance.currentUser!.sendEmailVerification();
                  Navigator.pop(context);
                  showMessage('A verification email has been sent.');
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
