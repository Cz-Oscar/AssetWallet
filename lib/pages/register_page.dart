import 'package:flutter/material.dart';

import 'package:flutter_asset_wallet/components/button.dart';
import 'package:flutter_asset_wallet/components/square_box.dart';
import 'package:flutter_asset_wallet/components/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Sign in method
  void signUserUp() async {
    final email = usernameController.text.trim();
    final password = passwordController.text.trim();

    // Display loading screen
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // try create user

    try {
      // Attempt sign in

      //check if password are equal
      if (passwordController.text != confirmPasswordController.text) {
        if (mounted) Navigator.pop(context);
        showErrorMessage('Passwords not equal');
        return;
      }
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Close loading dialog on success
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      // Close loading dialog and show error message
      if (mounted) Navigator.pop(context);
      showErrorMessage(e.code);
    } catch (e) {
      // Close loading dialog on any unexpected error
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
                const SizedBox(
                  height: 10,
                ),
                // Entrance logo
                const Icon(
                  Icons.lock,
                  size: 70,
                ),
                const SizedBox(
                  height: 20,
                ),
                // Register message
                const Text(
                  'Create account!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(
                  height: 50,
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(' Or continue with '),
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
                  children: const [
                    SquareBox(imagePath: 'lib/images/google_logo.png'),
                    SizedBox(width: 35),
                    SquareBox(imagePath: 'lib/images/apple_logo.png'),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),

                // Register button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Have account?'),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          color: Colors.amberAccent,
                          fontWeight: FontWeight.bold,
                        ),
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
