import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_asset_wallet/pages/add_investement_page.dart';
import 'package:flutter_asset_wallet/pages/charts_page.dart';
import 'package:flutter_asset_wallet/pages/portfolio_page.dart';
import 'package:flutter_asset_wallet/pages/settings_page.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // index

  double totalPortfolioValue = 0.0; // user's value
  double currentPortfolioValue = 0.0; // actual value
  

  void updatePortfolioValues(double totalValue, double currentValue) {
    setState(() {
      totalPortfolioValue = totalValue;
      currentPortfolioValue = currentValue;
    });
  }

  List<Widget> get _pages => [
        AddInvestmentPage(),
        PortfolioPage(
          onValuesCalculated: updatePortfolioValues, // callback
        ),
        ChartsPage(
          totalPortfolioValue: totalPortfolioValue,
          currentPortfolioValue: currentPortfolioValue,
        ),
        SettingsPage(
          loggedInUser: FirebaseAuth.instance.currentUser?.email ?? 'Guest',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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
            padding: const EdgeInsets.all(18),
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            tabs: const [
              GButton(
                icon: Icons.add,
                text: 'Dodaj',
              ),
              GButton(
                icon: Icons.account_balance_wallet_sharp,
                text: 'Portfel',
              ),
              GButton(
                icon: Icons.pie_chart,
                text: 'Wykres',
              ),
              GButton(
                icon: Icons.settings_sharp,
                text: 'Ustawienia',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton:
          _selectedIndex == 1 // only on PortfolioPage
              ? FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 0; // come to AddInvestmentPage
                    });
                  },
                  backgroundColor: Colors.lightBlue,
                  foregroundColor: Colors.deepOrange[300], 
                  child: const Icon(Icons.add),
                )
              : null, //no buttons on other sites
    );
  }
}
