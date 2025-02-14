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

  String formatPrice(double price) {
    // Formatuj z maksymalnie 5 miejscami po przecinku
    String formatted = price.toStringAsFixed(5);

    // Usuń nadmiarowe zera i kropkę, jeśli niepotrzebne
    if (formatted.contains('.')) {
      formatted =
          formatted.replaceAll(RegExp(r'0+$'), ''); // Usuń zerowe końcówki
      formatted = formatted.replaceAll(
          RegExp(r'\.$'), ''); // Usuń kropkę, jeśli na końcu
    }

    return formatted;
  }

// funkcje do pobierania obrazów
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
        setState(() {
          totalPortfolioValue = 0.0;
          currentPortfolioValue = 0.0;
          isLoading = false;
        });
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
      print("🔥 Pobrane ceny w aplikacji: $prices");

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

          // Oblicz wartość wg rynku na podstawie AKTUALNYCH cen z API
          if (prices.containsKey(id) && prices[id] != null) {
            final marketPrice = prices[id] ?? 0.0;
            dailyMarketValue += marketPrice * amount;
          } else {
            print(
                "⚠️ Brak aktualnej ceny dla $id – używam ostatniej historycznej");
            final marketPrice = historicalPrices[id]?[i] ?? 0.0;
            dailyMarketValue += marketPrice * amount;
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
      print("Nowa wartość wg zakupu: $totalValue");
      print("Nowa wartość wg rynku: $currentValue");

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

      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('investments')
          .doc(id)
          .delete();

      double defaultValue = 0.0;
      // Pobierz wszystkie pozostałe inwestycje użytkownika
      QuerySnapshot investmentsSnapshot =
          await userDoc.collection('investments').get();

      for (var doc in investmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        double price = (data['price'] ?? 0.0).toDouble();
        double amount = (data['amount'] ?? 0.0).toDouble();
        defaultValue += price * amount;
      }

      await _calculatePortfolioValues();
      // Zaktualizuj pole lastActiveAt
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'default_value': defaultValue,
      });
      print("Zaktualizowano default_value dla użytkownika $uid: $defaultValue");

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

                      const SizedBox(height: 16), // Odstęp między wartościami
                      const Text(
                        'Zmiana wartości portfela:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${percentageChange.toStringAsFixed(2)}%', // Zaokrąglona wartość do 2 miejsc po przecinku
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: percentageChange >= 0
                              ? Colors.green
                              : Colors
                                  .red, // Zielony dla wzrostu, czerwony dla spadku
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
                              _getCryptoImage(
                                  symbol), // Pobierz obraz kryptowaluty
                              _getExchangeImage(
                                  exchange), // Pobierz obraz giełdy
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
