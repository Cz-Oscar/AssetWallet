import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/portfolio_chart.dart';
import 'package:flutter_asset_wallet/portfolio_data.dart';
import 'package:flutter_asset_wallet/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChartsPage extends StatefulWidget {
  const ChartsPage({Key? key}) : super(key: key);

  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  List<PortfolioData> chartData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
    setState(() => isLoading = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('investments')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final ids = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['id'] ?? '')
          .where((id) => id.isNotEmpty)
          .cast<String>()
          .toList();

      final historicalPrices =
          await ApiService().getHistoricalPricesWithFirebase(uid, ids, 7);

      List<PortfolioData> tempChartData = [];
      for (int i = 0; i < 7; i++) {
        double dailyUserValue = 0.0;
        double dailyMarketValue = 0.0;

        final dateForDay = DateTime.now().subtract(Duration(days: 6 - i));
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] ?? 0.0).toDouble();
          final price = (data['price'] ?? 0.0).toDouble();
          final id = data['id'] ?? '';

          final purchaseDate = (data['date'] as Timestamp).toDate();
          if (purchaseDate.isAfter(dateForDay)) continue;

          dailyUserValue += price * amount;

          if (historicalPrices.containsKey(id)) {
            final marketPrice = historicalPrices[id]?[i] ?? 0.0;
            dailyMarketValue += marketPrice * amount;
          }
        }

        tempChartData
            .add(PortfolioData(dateForDay, dailyUserValue, dailyMarketValue));
      }

      setState(() {
        chartData = tempChartData;
        isLoading = false;
      });
    } catch (e) {
      print("Błąd podczas pobierania danych do wykresu: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Zmiany wartości portfela w ostatnich 7 dniach',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 5),
                          const Text('Wartość użytkownika'),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 5),
                          const Text('Wartość rynkowa'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: PortfolioChart(chartData),
                  ),
                ],
              ),
            ),
    );
  }
}
