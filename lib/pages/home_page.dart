import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final user = FirebaseAuth.instance.currentUser!;

  // sign out
  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: Colors.lightBlue,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 10),
          child: GNav(
              backgroundColor: Colors.lightBlue,
              color: Colors.black,
              activeColor: Colors.deepOrange[300],
              tabBackgroundColor: Colors.lightBlueAccent,
              gap: 6,
              onTabChange: (index) {
                print(index);
              },
              padding: EdgeInsets.all(18),
              haptic: true,
              tabs: const [
                GButton(
                  icon: Icons.home,
                  text: 'Home',
                ),
                GButton(
                  icon: Icons.favorite_outlined,
                  text: 'favorite',
                ),
                GButton(
                  icon: Icons.pie_chart,
                  text: 'charts',
                ),
                GButton(
                  icon: Icons.settings_sharp,
                  text: 'settings',
                ),
              ]),
        ),
      ),
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: signUserOut,
            icon: Icon(Icons.logout_outlined),
          )
        ],
      ),
      body: Center(
        child: Text(
          "You are logged in as: " + user.email!,
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}
