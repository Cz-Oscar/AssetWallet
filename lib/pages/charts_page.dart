import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/portfolio_chart.dart';
import 'package:flutter_asset_wallet/portfolio_data.dart';
import 'package:flutter_asset_wallet/services/api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChartsPage extends StatefulWidget {
  final double totalPortfolioValue;
  final double currentPortfolioValue;
  const ChartsPage({
    Key? key,
    required this.totalPortfolioValue,
    required this.currentPortfolioValue,
  }) : super(key: key);

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
    // print(
    //     "📊 Otrzymane wartości w ChartsPage: total=${widget.totalPortfolioValue}, current=${widget.currentPortfolioValue}");

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

      // download historical prices
      final historicalPrices =
          await ApiService().getHistoricalPricesWithFirebase(uid, ids, 7);

      // download actual cryptocurrency
      final prices = await ApiService().getCurrentPrices(ids);
      // print("🔥 Aktualne ceny w charts_page: $prices");

      // fill chart
      chartData.clear();
      for (int i = 0; i < 6; i++) {
        DateTime dateForDay = DateTime.now().subtract(Duration(days: 6 - i));

        double dailyUserValue = 0.0;
        double dailyMarketValue = 0.0;

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          double price = (data['price'] ?? 0.0).toDouble();
          double amount = (data['amount'] ?? 0.0).toDouble();
          String id = data['id'] ?? '';

          DateTime purchaseDate = (data['date'] as Timestamp).toDate();
          if (purchaseDate.isAfter(dateForDay)) continue;

          dailyUserValue += price * amount;

          if (historicalPrices.containsKey(id) &&
              historicalPrices[id] != null) {
            final marketPrice = historicalPrices[id]?[i] ?? 0.0;
            dailyMarketValue += marketPrice * amount;
          }
        }

        chartData
            .add(PortfolioData(dateForDay, dailyUserValue, dailyMarketValue));
      }
      DateTime today = DateTime.now();
      double todayUserValue = widget.totalPortfolioValue;
      double todayMarketValue = widget.currentPortfolioValue;

      chartData.removeWhere((data) =>
          data.date.day == DateTime.now().day &&
          data.date.month == DateTime.now().month &&
          data.date.year == DateTime.now().year);

      // add today's date
      chartData.add(PortfolioData(today, todayUserValue, todayMarketValue));

      // print("🔥 Poprawione dane wykresu (ostatni dzień): ${chartData.last}");
      // print("📅 Daty w chartData:");
      for (var data in chartData) {
        print("${data.date}");
      }

      setState(() {
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
      appBar: AppBar(
        title: const Text('Wykres'),
        backgroundColor: Colors.lightBlue,
      ),
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
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Wartość inwestycji',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            color: Colors.deepOrange[300],
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Obecna Wartość',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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
