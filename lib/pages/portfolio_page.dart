import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_asset_wallet/services/api_service.dart';
import 'package:flutter_asset_wallet/portfolio_data.dart';

class PortfolioPage extends StatefulWidget {
  final Function(double totalValue, double currentValue) onValuesCalculated;

  const PortfolioPage({Key? key, required this.onValuesCalculated})
      : super(key: key);

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  double totalPortfolioValue = 0.0; // Portfolio value based on purchase
  double currentPortfolioValue = 0.0; // Portfolio value based on market price
  List<PortfolioData> chartData = []; // List of historical data
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculatePortfolioValues();
  }

  String formatPrice(double price) {
// Format with a maximum of 5 decimal places
    String formatted = price.toStringAsFixed(5);

// Remove unnecessary trailing zeros and dot if not needed
    if (formatted.contains('.')) {
      formatted =
          formatted.replaceAll(RegExp(r'0+$'), ''); // Remove trailing zeros
      formatted =
          formatted.replaceAll(RegExp(r'\.$'), ''); // Remove dot if at the end
    }

    return formatted;
  }

// Functions for fetching images
  Future<String?> _getCryptoImage(String symbol) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('metadata')
          .doc('cryptocurrencies')
          .get();
      final data = snapshot.data()?['data'] as List<dynamic>?;
      final crypto = data?.firstWhere(
        (crypto) =>
            crypto['symbol'].toString().toLowerCase() == symbol.toLowerCase(),
        orElse: () => null,
      );
      return crypto?['image'];
    } catch (e) {
      print('Błąd pobierania obrazu kryptowaluty: $e');
      return null;
    }
  }

  Future<String?> _getExchangeImage(String exchangeName) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('metadata')
          .doc('exchanges')
          .get();
      final data = snapshot.data()?['data'] as List<dynamic>?;
      final exchange = data?.firstWhere(
        (ex) =>
            ex['name'].toString().toLowerCase() == exchangeName.toLowerCase(),
        orElse: () => null,
      );
      return exchange?['image'];
    } catch (e) {
      print('Błąd pobierania obrazu giełdy: $e');
      return null;
    }
  }

  Future<void> _calculatePortfolioValues() async {
    setState(() => isLoading = true);

    double totalValue = 0.0;
    double currentValue = 0.0;

    try {
      // get investments from Firebase
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('investments')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          totalPortfolioValue = 0.0;
          currentPortfolioValue = 0.0;
          isLoading = false;
        });
        return;
      }

// Extract cryptocurrency IDs from investments
      final ids = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['id'] ?? '')
          .where((id) => id.isNotEmpty)
          .cast<String>()
          .toList();

      if (ids.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

// Fetch current cryptocurrency prices
      final prices = await ApiService().getCurrentPrices(ids);
      // print("🔥 Pobrane ceny w aplikacji: $prices");

// Fetch historical cryptocurrency prices from the last 7 days
      final historicalPrices =
          await ApiService().getHistoricalPricesWithFirebase(uid, ids, 7);

// Prepare data for the chart (last 7 days)
      List<PortfolioData> chartData = [];
      for (int i = 0; i < 7; i++) {
        double dailyUserValue = 0.0;
        double dailyMarketValue = 0.0;

        final dateForDay = DateTime.now()
            .subtract(Duration(days: 6 - i)); // Date for the current day

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          double price = (data['price'] ?? 0.0).toDouble();
          double amount = (data['amount'] ?? 0.0).toDouble();
          String id = data['id'] ?? '';

          DateTime? purchaseDate;
          if (data['date'] != null && data['date'] is Timestamp) {
            purchaseDate = (data['date'] as Timestamp).toDate();
          } else {
            print(
                "Nieprawidłowe lub brakujące pole 'date' w dokumencie: $data");
            continue; // Pomijamy dokument bez prawidłowej daty
          }

// Include only assets purchased before the given day
          if (purchaseDate.isAfter(dateForDay)) continue;

// Calculate value based on purchase
          dailyUserValue += price * amount;

// Calculate value based on market price using CURRENT prices from API
          if (prices.containsKey(id) && prices[id] != null) {
            final marketPrice = prices[id] ?? 0.0;
            dailyMarketValue += marketPrice * amount;
          } else {
            // print(
            // "⚠️ Brak aktualnej ceny dla $id – używam ostatniej historycznej");
            final marketPrice = historicalPrices[id]?[i] ?? 0.0;
            dailyMarketValue += marketPrice * amount;
          }
        }

        // add data to chart
        chartData.add(
          PortfolioData(
            dateForDay,
            dailyUserValue,
            dailyMarketValue,
          ),
        );

// If it's today's date, set totalValue and currentValue
        if (i == 6) {
          totalValue = dailyUserValue;
          currentValue = dailyMarketValue;
        }
      }

// Save `totalValue` to Firestore as `default_value`
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'default_value': totalValue,
      });
      // print("Nowa wartość wg zakupu: $totalValue");
      // print("Nowa wartość wg rynku: $currentValue");

// Set new portfolio values
      setState(() {
        totalPortfolioValue = totalValue;
        currentPortfolioValue = currentValue;
        chartData = chartData; // Store generated data in state
      });

// Pass values to parent
      widget.onValuesCalculated(totalValue, currentValue);

// Display chart data (for debugging purposes)
      for (var data in chartData) {
        // print(
        //     'Date: ${data.date}, UserValue: ${data.userValue}, MarketValue: ${data.marketValue}');
      }
    } catch (e) {
      print("Błąd podczas obliczania wartości portfela: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteInvestment(String id, String assetName) async {
    try {
      setState(() => isLoading = true);

      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('investments')
          .doc(id)
          .delete();

      double defaultValue = 0.0;
// Retrieve all remaining user investments
      QuerySnapshot investmentsSnapshot =
          await userDoc.collection('investments').get();

      for (var doc in investmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        double price = (data['price'] ?? 0.0).toDouble();
        double amount = (data['amount'] ?? 0.0).toDouble();
        defaultValue += price * amount;
      }

      await _calculatePortfolioValues();
// Update the `lastActiveAt` field

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'default_value': defaultValue,
      });
      // print("Zaktualizowano default_value dla użytkownika $uid: $defaultValue");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usunięto inwestycję: $assetName'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Błąd podczas usuwania inwestycji: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Brak daty';
    final date = (timestamp as Timestamp).toDate();
    return '${date.day}-${date.month}-${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    double percentageChange = totalPortfolioValue == 0
        ? 0
        : ((currentPortfolioValue - totalPortfolioValue) /
                totalPortfolioValue) *
            100;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfel'),
        backgroundColor: Colors.lightBlue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Wartość inwestycji:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '\$${formatPrice(totalPortfolioValue)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Obecna wartość portfela:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '\$${formatPrice(currentPortfolioValue)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange[300],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Zmiana wartości portfela:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${percentageChange.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color:
                              percentageChange >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('investments')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final investments = snapshot.data!.docs;

                      if (investments.isEmpty) {
                        return const Center(
                          child: Text(
                            ' Brak aktywów w portfelu. Dodaj pierwszą        inwestycje kliknij + w prawym dolnym rogu!',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: investments.length,
                        itemBuilder: (context, index) {
                          final data =
                              investments[index].data() as Map<String, dynamic>;
                          final symbol = data['symbol'] ?? 'Brak symbolu';
                          final asset = data['asset'] ?? 'Brak aktywa';
                          final exchange = data['exchange'] ?? 'Brak giełdy';
                          final price = (data['price'] ?? 0.0).toDouble();
                          final amount = (data['amount'] ?? 0.0).toDouble();
                          final value = price * amount;

                          return FutureBuilder<List<String?>>(
                            future: Future.wait([
                              _getCryptoImage(symbol),
                              _getExchangeImage(exchange),
                            ]),
                            builder: (context, snapshot) {
                              final images = snapshot.data ?? [null, null];
                              final cryptoImage =
                                  images[0] ?? 'https://via.placeholder.com/40';
                              final exchangeImage =
                                  images[1] ?? 'https://via.placeholder.com/40';

                              return Card(
                                elevation: 2,
                                child: ListTile(
                                  leading: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.network(
                                        cryptoImage,
                                        width: 30,
                                        height: 30,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                    Icons.image_not_supported),
                                      ),
                                      const SizedBox(width: 8),
                                      Image.network(
                                        exchangeImage,
                                        width: 30,
                                        height: 30,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.business),
                                      ),
                                    ],
                                  ),
                                  title: Text(symbol.toUpperCase()),
                                  subtitle: Text(
                                    'Giełda: $exchange\n'
                                    'Cena zakupu: \$${formatPrice(price)}\n'
                                    'Ilość: ${formatPrice(amount)}\n'
                                    'Wartość: \$${formatPrice(value)}\n'
                                    'Data zakupu: ${_formatDate(data['date'])}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteInvestment(
                                        investments[index].id, asset),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
