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
  double totalPortfolioValue = 0.0; // Wartość portfela wg zakupu
  double currentPortfolioValue = 0.0; // Wartość portfela wg rynku
  List<PortfolioData> chartData = []; // Lista danych historycznych

  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculatePortfolioValues();
  }

  Future<void> _calculatePortfolioValues() async {
    setState(() => isLoading = true);

    double totalValue = 0.0; // Wartość portfela wg zakupu
    double currentValue = 0.0; // Wartość portfela wg rynku

    try {
      // Pobierz inwestycje z Firebase
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('investments')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      // Wyodrębnij ID kryptowalut z inwestycji
      final ids = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['id'] ?? '')
          .where((id) => id.isNotEmpty)
          .cast<String>()
          .toList();

      if (ids.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      // Pobierz aktualne ceny kryptowalut
      final prices = await ApiService().getCurrentPrices(ids);

      // Pobierz historyczne ceny kryptowalut z ostatnich 7 dni
      final historicalPrices =
          await ApiService().getHistoricalPricesWithFirebase(uid, ids, 7);

      // Przygotuj dane dla wykresu (ostatnie 7 dni)
      List<PortfolioData> chartData = [];
      for (int i = 0; i < 7; i++) {
        double dailyUserValue = 0.0; // Wartość wg zakupu
        double dailyMarketValue = 0.0; // Wartość wg rynku

        final dateForDay = DateTime.now()
            .subtract(Duration(days: 6 - i)); // Data dla bieżącego dnia

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Pobierz dane z dokumentu
          double price = (data['price'] ?? 0.0).toDouble();
          double amount = (data['amount'] ?? 0.0).toDouble();
          String id = data['id'] ?? '';

          // Pobierz datę zakupu
          DateTime? purchaseDate;
          if (data['date'] != null && data['date'] is Timestamp) {
            purchaseDate = (data['date'] as Timestamp).toDate();
          } else {
            print(
                "Nieprawidłowe lub brakujące pole 'date' w dokumencie: $data");
            continue; // Pomijamy dokument bez prawidłowej daty
          }

          // Uwzględnij tylko dane dla aktywów zakupionych przed danym dniem
          if (purchaseDate.isAfter(dateForDay)) continue;

          // Oblicz wartość wg zakupu
          dailyUserValue += price * amount;

          // Oblicz wartość wg rynku na podstawie historycznych cen
          if (historicalPrices.containsKey(id) &&
              historicalPrices[id] != null) {
            final marketPrice = historicalPrices[id]?[i] ?? 0.0;
            dailyMarketValue += marketPrice * amount;
          } else {
            print("Brak historycznych danych dla ID: $id");
          }
        }

        // Dodaj dane do wykresu
        chartData.add(
          PortfolioData(
            dateForDay,
            dailyUserValue,
            dailyMarketValue,
          ),
        );

        // Jeśli to dzisiejszy dzień, ustaw totalValue i currentValue
        if (i == 6) {
          totalValue = dailyUserValue;
          currentValue = dailyMarketValue;
        }
      }

// Zapisz `totalValue` do Firestore jako `default_value`
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'default_value': totalValue,
      });

      // Ustaw nowe wartości portfela
      setState(() {
        totalPortfolioValue = totalValue;
        currentPortfolioValue = currentValue;
        chartData = chartData; // Przechowaj wygenerowane dane w stanie
      });

      // Przekaż wartości do rodzica
      widget.onValuesCalculated(totalValue, currentValue);

      // Wyświetl dane wykresu (na potrzeby debugowania)
      for (var data in chartData) {
        print(
            'Date: ${data.date}, UserValue: ${data.userValue}, MarketValue: ${data.marketValue}');
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
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('investments')
          .doc(id)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usunięto inwestycję: $assetName'),
          duration: const Duration(seconds: 2),
        ),
      );

      await _calculatePortfolioValues();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
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
                        'Wartość portfela wg zakupu:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '\$${totalPortfolioValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Wartość portfela wg rynku:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '\$${currentPortfolioValue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
                          child: Text('Brak aktywów w portfelu.'),
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
                          final iconUrl = data['iconUrl'] ??
                              'https://via.placeholder.com/40';

                          return Card(
                            elevation: 2,
                            child: ListTile(
                              leading: Image.network(
                                iconUrl,
                                width: 30,
                                height: 30,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.image_not_supported),
                              ),
                              title: Text(symbol.toUpperCase()),
                              subtitle: Text(
                                'Giełda: $exchange\n'
                                'Cena zakupu: \$${price.toStringAsFixed(2)}\n'
                                'Ilość: ${amount.toStringAsFixed(2)}\n'
                                'Wartość: \$${value.toStringAsFixed(2)}\n'
                                'Data zakupu: ${_formatDate(data['date'])}',
                              ),
                              trailing: IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteInvestment(
                                    investments[index].id, asset),
                              ),
                            ),
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
