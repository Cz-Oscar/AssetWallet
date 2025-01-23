import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_asset_wallet/components/button.dart';
import 'package:flutter_asset_wallet/components/square_box.dart';
import 'package:flutter_asset_wallet/components/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_asset_wallet/main.dart';
import 'package:flutter_asset_wallet/services/auth_service.dart';
import 'package:flutter_asset_wallet/services/firebase_service.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // Text editing controllers for email and password fields
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Stałe dla odstępów
  final double iconTopPadding = 10.0; // Odstęp na górze dla ikonki
  final double iconSize = 70.0; // Rozmiar ikonki kłódki
  final double titlePadding = 40.0; // Odstęp pod ikonką dla napisu
  final double formStartPadding = 50.0; // Odstęp od tytułu do pól tekstowych

  // bold white style for Log in
  final TextStyle boldTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  // black style for rest
  final TextStyle blackTextStyle = TextStyle(
    color: Colors.black,
    fontSize: 15,
  );

  // Sign in method
  void signUserUp() async {
    final email = usernameController.text.trim();
    final password = passwordController.text.trim();

    // Wyświetl ekran ładowania
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Sprawdź, czy hasła są identyczne
      if (passwordController.text != confirmPasswordController.text) {
        if (mounted) Navigator.pop(context); // Zamknij ekran ładowania
        showErrorMessage('Passwords do not match');
        return;
      }

      // Zarejestruj użytkownika
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Pobierz UID użytkownika
      final userId = userCredential.user?.uid ?? '';

      if (userId.isNotEmpty) {
        // Rozpocznij sprawdzanie powiadomień
        startNotificationCheck(userId);
      }

      // Zapisz dane użytkownika w Firestore
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'email': email,
          'createdAt': DateTime.now(),
        });
      }

      // Zamknij ekran ładowania po sukcesie
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // Zamknij ekran ładowania i wyświetl komunikat o błędzie
      if (mounted) Navigator.pop(context);
      showErrorMessage(e.code);
    } catch (e) {
      // Zamknij ekran ładowania i wyświetl komunikat o nieoczekiwanym błędzie
      if (mounted) Navigator.pop(context);
      showErrorMessage('Unexpected error occurred');
    }
  }

  // Method to show error message to the user
  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(
            child: Text(
              message,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: iconTopPadding), // Odstęp na górze
                Icon(Icons.lock, size: iconSize), // Ikona
                SizedBox(height: titlePadding), // Odstęp pod ikoną
                // Register message
                const Text(
                  'Create account!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                SizedBox(
                  height: formStartPadding,
                ),

                // Username or email field
                MyTextField(
                  controller: usernameController,
                  hintText: 'Username or e-mail',
                  obscureText: false,
                ),
                const SizedBox(
                  height: 10,
                ),

                // Password field
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(
                  height: 10,
                ),

                // Confirm Password field
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(
                  height: 10,
                ),

                const SizedBox(
                  height: 5,
                ),

                // Sign up button
                MyButton(
                  text: "Sign up",
                  onTap: signUserUp,
                ),
                const SizedBox(
                  height: 50,
                ),

                // Log in with divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          thickness: 0.8,
                          color: Colors.black54,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          ' Or continue with ',
                          style: blackTextStyle,
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          thickness: 0.8,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),

                // Google and Apple buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareBox(
                        onTap: () => AuthService().signInWithGoogle(),
                        imagePath: 'lib/images/google_logo.png'),
                    SizedBox(width: 35),
                    SquareBox(
                        onTap: () => (),
                        imagePath: 'lib/images/apple_logo.png'),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),

                // Register button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Have account?',
                      style: blackTextStyle,
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Log in',
                        style: boldTextStyle,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
