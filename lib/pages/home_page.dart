import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/pages/add_investement_page.dart';
import 'package:flutter_asset_wallet/pages/settings_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Aktualny indeks wybranej zakładki

  // Lista widoków
  final List<Widget> _pages = [
    AddInvestmentPage(),
    Center(child: Text('Favorite Page')), // Placeholder
    Center(child: Text('Charts Page')), // Placeholder
    SettingsPage(
        loggedInUser: FirebaseAuth.instance.currentUser?.email ?? 'Guest'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Dynamiczna zawartość ekranu
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
            haptic: true,
            padding: EdgeInsets.all(18),
            selectedIndex: _selectedIndex, // Aktualny indeks
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index; // Zmiana indeksu
              });
            },
            tabs: const [
              GButton(
                icon: Icons.home,
                text: 'Home',
              ),
              GButton(
                icon: Icons.favorite_outlined,
                text: 'Favorite',
              ),
              GButton(
                icon: Icons.pie_chart,
                text: 'Charts',
              ),
              GButton(
                icon: Icons.settings_sharp,
                text: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
