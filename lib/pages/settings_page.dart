import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/main.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatelessWidget {
  final String loggedInUser; // Przekazanie nazwy użytkownika

  const SettingsPage({Key? key, required this.loggedInUser}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ustawienia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jesteś zalogowany jako: $loggedInUser',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                // Logika wylogowania
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => AuthStateHandler(),
                )); // Powrót do HomePage
              },
              icon: Icon(Icons.logout),
              label: Text('Wyloguj się'),
            ),
          ],
        ),
      ),
    );
  }
}
