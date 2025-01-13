// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_asset_wallet/services/api_service.dart';

// class PortfolioPage extends StatefulWidget {
//   final Function(double totalValue, double currentValue) onValuesCalculated;

//   const PortfolioPage({Key? key, required this.onValuesCalculated})
//       : super(key: key);

//   @override
//   State<PortfolioPage> createState() => _PortfolioPageState();
// }

// class _PortfolioPageState extends State<PortfolioPage> {
//   double totalPortfolioValue = 0.0; // Wartość portfela wg zakupu
//   double currentPortfolioValue = 0.0; // Wartość portfela wg rynku

//   final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
//   bool isLoading = false;
//   late Map<String, String> cryptoIdMap;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCryptoIdMap();
//   }

//   Future<void> _initializeCryptoIdMap() async {
//     try {
//       setState(() => isLoading = true);

//       cryptoIdMap = await ApiService().fetchCryptoSymbolToIdMap();
//       cryptoIdMap =
//           cryptoIdMap.map((key, value) => MapEntry(key.toLowerCase(), value));
//       await _calculatePortfolioValues();
//     } catch (e) {
//       print('Błąd inicjalizacji mapy symboli kryptowalut: $e');
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _calculatePortfolioValues() async {
//     setState(() {
//       isLoading = true;
//     });

//     double totalValue = 0.0;
//     double currentValue = 0.0;

//     try {
//       // Pobierz dokumenty inwestycji z Firebase
//       QuerySnapshot snapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('investments')
//           .get();

//       // Pobierz mapę symbol → ID
//       final symbolToIdMap = await ApiService().fetchCryptoSymbolToIdMap();

//       // Przygotuj listę symboli i zamień je na ID, odfiltrowując null
//       final ids = snapshot.docs
//           .map((doc) => (doc.data() as Map<String, dynamic>)['symbol'])
//           .where((symbol) => symbol != null)
//           .map((symbol) => symbol.toString().toLowerCase())
//           .map((symbol) => symbolToIdMap[symbol])
//           .where((id) => id != null)
//           .cast<String>() // Rzutowanie na List<String>
//           .toList();

//       if (ids.isEmpty) {
//         print("Brak ID do pobrania cen.");
//         return;
//       }
//       print("Wysyłanie zapytania dla ID: ${ids.join(',')}");

//       // Pobierz ceny dla ID
//       final prices = await ApiService().getCurrentPrices(ids);

//       print("Ceny otrzymane z API: $prices");

//       // Oblicz wartości portfela
//       for (var doc in snapshot.docs) {
//         final data = doc.data() as Map<String, dynamic>;
//         double price = (data['price'] ?? 0).toDouble();
//         double amount = (data['amount'] ?? 0).toDouble();
//         String symbol = (data['symbol'] ?? '').toLowerCase();

//         // Pobierz ID dla symbolu
//         final id = symbolToIdMap[symbol];
//         if (id != null && prices.containsKey(id)) {
//           final currentPrice = prices[id];
//           if (currentPrice != null) {
//             currentValue += currentPrice * amount;
//           } else {
//             print(
//                 "Brak danych cenowych dla ID $id (symbol: $symbol), pomijam.");
//           }
//         } else {
//           print("Brak ID dla symbolu: $symbol, pomijam.");
//         }
//       }

//       // Zaktualizuj wartości portfela
//       setState(() {
//         totalPortfolioValue = totalValue; // wg zakupu
//         currentPortfolioValue = currentValue; // wg rynku
//       });

//       // Przekaż dane do HomePage
//       widget.onValuesCalculated(totalValue, currentValue);
//     } catch (e) {
//       print("Błąd podczas obliczania wartości portfela: $e");
//     } finally {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _deleteInvestment(String id, String assetName) async {
//     try {
//       setState(() => isLoading = true);
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .collection('investments')
//           .doc(id)
//           .delete();

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Usunięto inwestycję: $assetName'),
//           duration: const Duration(seconds: 2),
//         ),
//       );

//       await _calculatePortfolioValues();
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   String _formatDate(dynamic timestamp) {
//     if (timestamp == null) return 'Brak daty'; // Jeśli brak daty
//     final date =
//         (timestamp as Timestamp).toDate(); // Konwersja Firebase Timestamp
//     return '${date.day}-${date.month}-${date.year}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Portfolio'),
//         backgroundColor: Colors.lightBlue,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     children: [
//                       const Text(
//                         'Wartość portfela wg zakupu:',
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.w500),
//                       ),
//                       Text(
//                         '\$${totalPortfolioValue.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green,
//                         ),
//                       ),
//                       const SizedBox(height: 16),
//                       const Text(
//                         'Wartość portfela wg rynku:',
//                         style: TextStyle(
//                             fontSize: 18, fontWeight: FontWeight.w500),
//                       ),
//                       Text(
//                         '\$${currentPortfolioValue.toStringAsFixed(2)}',
//                         style: const TextStyle(
//                           fontSize: 32,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Divider(),
//                 Expanded(
//                   child: StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(uid)
//                         .collection('investments')
//                         .orderBy('timestamp', descending: true)
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData) {
//                         return const Center(child: CircularProgressIndicator());
//                       }

//                       final investments = snapshot.data!.docs;

//                       if (investments.isEmpty) {
//                         return const Center(
//                           child: Text('Brak aktywów w portfelu.'),
//                         );
//                       }

//                       return ListView.builder(
//                         itemCount: investments.length,
//                         itemBuilder: (context, index) {
//                           final data =
//                               investments[index].data() as Map<String, dynamic>;
//                           final symbol = data['symbol'] ?? 'Brak symbolu';
//                           final asset = data['asset'] ?? 'Brak aktywa';
//                           final exchange = data['exchange'] ?? 'Brak giełdy';
//                           final price = (data['price'] ?? 0.0).toDouble();
//                           final amount = (data['amount'] ?? 0.0).toDouble();
//                           final value = price * amount; // Wartość wg zakupu
//                           final iconUrl = data['iconUrl'] ??
//                               'https://via.placeholder.com/40';
//                           final exchangeIconUrl = data['exchangeIconUrl'] ??
//                               'https://via.placeholder.com/40';

//                           return Card(
//                             elevation: 2,
//                             child: ListTile(
//                               leading: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   Image.network(
//                                     iconUrl,
//                                     width: 30,
//                                     height: 30,
//                                     errorBuilder: (context, error,
//                                             stackTrace) =>
//                                         const Icon(Icons.image_not_supported),
//                                   ),
//                                   const SizedBox(width: 5),
//                                   Image.network(
//                                     exchangeIconUrl,
//                                     width: 30,
//                                     height: 30,
//                                     errorBuilder: (context, error,
//                                             stackTrace) =>
//                                         const Icon(Icons.image_not_supported),
//                                   ),
//                                 ],
//                               ),
//                               title: Text(symbol.toUpperCase()),
//                               subtitle: Text(
//                                 'Giełda: $exchange\n'
//                                 'Cena zakupu: \$${price.toStringAsFixed(2)}\n'
//                                 'Ilość: ${amount.toStringAsFixed(2)}\n'
//                                 'Wartość: \$${value.toStringAsFixed(2)}\n'
//                                 'Data zakupu: ${_formatDate(data['timestamp'])}',
//                               ),
//                               trailing: IconButton(
//                                 icon:
//                                     const Icon(Icons.delete, color: Colors.red),
//                                 onPressed: () => _deleteInvestment(
//                                     investments[index].id, asset),
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_asset_wallet/services/api_service.dart';

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

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Pobierz dane z dokumentu
        double price = (data['price'] ?? 0.0).toDouble();
        double amount = (data['amount'] ?? 0.0).toDouble();
        String id = data['id'] ?? '';

        // Oblicz wartość inwestycji na podstawie zakupionej ilości
        totalValue += price * amount;

        // Oblicz wartość rynkową
        if (prices.containsKey(id)) {
          final marketPrice = prices[id]!;
          currentValue += marketPrice * amount;
        } else {
          print("Brak aktualnych danych cenowych dla ID: $id");
        }
      }

      // Ustaw nowe wartości portfela
      setState(() {
        totalPortfolioValue = totalValue;
        currentPortfolioValue = currentValue;
      });

      // Przekaż wartości do rodzica
      widget.onValuesCalculated(totalValue, currentValue);
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
                                'Data zakupu: ${_formatDate(data['timestamp'])}',
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
