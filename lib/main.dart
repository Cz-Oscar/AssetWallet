import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Dodaj Firebase Core
import 'firebase_options.dart'; // Import konfiguracji Firebase (wygenerowane przez flutterfire configure)
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // Umożliwia inicjalizację asynchroniczną
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Inicjalizacja Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
