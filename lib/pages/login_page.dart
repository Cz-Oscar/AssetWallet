import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/components/button.dart';
import 'package:flutter_asset_wallet/components/square_box.dart';
import 'package:flutter_asset_wallet/components/textfield.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  // text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  //sign user in method
  void signUserIn() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 10,
              ),
              // entrance logo
              Icon(
                Icons.lock,
                size: 70,
              ),
              const SizedBox(
                height: 40,
              ),
              // welcome
              Text(
                'Witaj ponownie!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                ),
              ),

              const SizedBox(
                height: 50,
              ),

              //username field

              MyTextField(
                controller: usernameController,
                hintText: 'Username or e-mail',
                obscureText: false,
              ),
              const SizedBox(
                height: 10,
              ),

              //password field

              MyTextField(
                controller: passwordController,
                hintText: 'Password ',
                obscureText: true,
              ),

              const SizedBox(
                height: 10,
              ),

              // forgot password button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: const Color.fromARGB(
                          255,
                          81,
                          27,
                          27,
                        ),
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              //sign in button

              MyButton(
                onTap: signUserIn,
              ),

              const SizedBox(
                height: 50,
              ),

              // log in with

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.8,
                        color: Colors.black54,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(' Or continue with '),
                    ),
                    Expanded(
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
              // google

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  // google

                  SquareBox(imagePath: 'lib/images/google_logo.png'),

                  const SizedBox(width: 35),

                  // apple

                  SquareBox(imagePath: 'lib/images/apple_logo.png'),
                ],
              ),

              const SizedBox(
                height: 50,
              ),

              // register button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No account?'),
                  const SizedBox(
                    width: 6,
                  ),
                  const Text(
                    'Register',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
