import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Dodaj Firebase Core
import 'package:flutter_asset_wallet/pages/auth_page.dart';
import 'firebase_options.dart'; // Import konfiguracji Firebase (wygenerowane przez flutterfire configure)

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthPage(),
    );
  }
}
