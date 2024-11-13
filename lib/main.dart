import 'package:loocator/utils/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:loocator/constants.dart';
import 'package:loocator/pages/navigation_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseUIAuth.configureProviders(
      [EmailAuthProvider(), GoogleProvider(clientId: GOOGLE_CLIENT_ID)]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loocator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        buttonTheme: ButtonThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        ),
        useMaterial3: true,
      ),
      home: const NavigationPage(), //MapPage(),
    );
  }
}
