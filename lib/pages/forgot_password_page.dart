import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/components/button.dart';
import 'package:flutter_asset_wallet/components/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailController = TextEditingController();

  // Stałe dla odstępów
  final double iconTopPadding = 10.0; // Odstęp na górze dla ikonki
  final double iconSize = 70.0; // Rozmiar ikonki kłódki
  final double titlePadding = 40.0; // Odstęp pod ikonką dla napisu
  final double formStartPadding = 50.0; // Odstęp od tytułu do pól tekstowych

  final TextStyle boldTextStyle = const TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );

  final TextStyle blackTextStyle = const TextStyle(
    color: Colors.black,
    fontSize: 15,
  );

  // Funkcja resetowania hasła
  void resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showErrorMessage("Please enter your email");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Center(child: Text("Success!")),
          content: const Text("Password reset email sent! Check your inbox."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      showErrorMessage(e.message ?? "An error occurred.");
    } catch (e) {
      showErrorMessage("Unexpected error occurred. Try again later.");
    }
  }

  void showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Center(child: Text("Error")),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
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
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: formStartPadding), // Odstęp do formularza

                // Email input
                MyTextField(
                  controller: emailController,
                  hintText: 'Enter your email',
                  obscureText: false,
                ),
                const SizedBox(height: 20),

                // Reset button
                MyButton(
                  text: "Reset Password",
                  onTap: resetPassword,
                ),

                const SizedBox(height: 50),

                // Powrót do logowania
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Remember your password?', style: blackTextStyle),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Log in', style: boldTextStyle),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
