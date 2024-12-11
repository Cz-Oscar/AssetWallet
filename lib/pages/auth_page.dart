import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/pages/home_page.dart';
import 'package:flutter_asset_wallet/pages/login_or_register_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthStateHandler(),
    );
  }
}

class AuthStateHandler extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading spinner while checking authentication state
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // If user is logged in, show HomePage
          return HomePage();
        } else {
          // If user is not logged in, show LoginOrRegisterPage
          return const LoginOrRegisterPage();
        }
      },
    );
  }
}
