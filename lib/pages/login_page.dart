import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/components/button.dart';
import 'package:flutter_asset_wallet/components/square_box.dart';
import 'package:flutter_asset_wallet/components/textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_asset_wallet/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Text editing controllers for email and password fields
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  // Sign in method
  void signUserIn() async {
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

    // try login

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
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
                  height: 40,
                ),
                // Welcome message
                const Text(
                  'Welcome back!',
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

                // Forgot password button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 25,
                ),

                // Sign in button
                MyButton(
                  text: "Sign in",
                  onTap: signUserIn,
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
                  children: [
                    SquareBox(
                        onTap: () => AuthService().signInWithGoogle(),
                        imagePath: 'lib/images/google_logo.png'),
                    SizedBox(width: 35),
                    SquareBox(
                        onTap: () => AuthService().signInWithGoogle(),
                        imagePath: 'lib/images/apple_logo.png'),
                  ],
                ),
                const SizedBox(
                  height: 50,
                ),

                // Register button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('No account?'),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Register',
                        style: TextStyle(
                          color: Colors.white,
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
