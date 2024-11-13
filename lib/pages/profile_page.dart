import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loocator/utils/firebase_ui_auth.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController displayName = TextEditingController();
  TextEditingController email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
        ),
        backgroundColor: Theme.of(context).primaryColorLight,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              FirebaseUIAuth.signOut(context: context);
              showMessage('Logged Out');
            },
            label: const Text('Log Out'),
            icon: const Icon(Icons.logout),
            style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Colors.black)),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 75.0, 16.0, 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Profile Image
              Container(
                foregroundDecoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(25)),
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(25)),
                clipBehavior: Clip.antiAlias,
                child: const Column(
                  children: [
                    Image(
                      image:
                          AssetImage('assets/images/defaultProfilePicture.jpg'),
                      width: 200,
                      height: 200,
                    ),
                    // Maybe add a change profile image button
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // Display Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.maxFinite,
                      child: TextField(
                        maxLines: 1,
                        controller: displayName,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            labelText: 'Display Name',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            hintText: '${currentUser!.displayName}',
                            hintStyle:
                                const TextStyle(fontWeight: FontWeight.normal)),
                      ),
                    ),
                    const Text(
                      'By default, your display name is the username from your email address.',
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // Email
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.maxFinite,
                      child: TextField(
                        maxLines: 1,
                        controller: email,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            labelText: 'Email',
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            hintText: '${currentUser.email}',
                            hintStyle:
                                const TextStyle(fontWeight: FontWeight.normal)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // Save and Discard Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        displayName.clear();
                        email.clear();
                      },
                      child: const Text('Discard Changes')),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (displayName.text.isNotEmpty) {
                            currentUser.updateDisplayName(displayName.text);
                          }
                          if (email.text.isNotEmpty) {
                            currentUser.verifyBeforeUpdateEmail(email.text);
                          }
                          if (displayName.text.isEmpty && email.text.isEmpty) {
                            showMessage('Nothing to be saved.');
                          } else {
                            showMessage('Changes Updated');
                            displayName.clear();
                            email.clear();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorLight),
                      child: const Text('Save Changes')),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void showMessage(String message) {
    final SnackBar snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
