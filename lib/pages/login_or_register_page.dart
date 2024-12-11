import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/pages/login_page.dart';

import 'register_page.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({super.key});

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  //show login page
  bool showLoginPage = true;

  // switch between login or register page
  void SwitchPages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: SwitchPages,
      );
    } else {
      return RegisterPage(
        onTap: SwitchPages,
      );
    }
  }
}
