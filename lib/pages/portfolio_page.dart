import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firebase Firestore
import 'package:flutter_asset_wallet/pages/add_investement_page.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  double totalPortfolioValue = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateTotalPortfolioValue();
  }

  Future<void> _calculateTotalPortfolioValue() async {
    double totalValue = 0.0;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('investments')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      double price = (data['price'] ?? 0).toDouble();
      totalValue += price;
    }

    setState(() {
      totalPortfolioValue = totalValue;
    });
  }

  Future<void> _deleteInvestment(String id, String assetName) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('investments')
        .doc(id)
        .delete();

    // Wyświetlenie komunikatu SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Usunięto inwestycję: $assetName'),
        duration: const Duration(seconds: 2),
      ),
    );

    _calculateTotalPortfolioValue(); // Aktualizacja wartości po usunięciu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        backgroundColor: Colors.lightBlue,
      ),
      body: Column(
        children: [
          // Wyświetlenie ogólnej wartości portfela
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Całkowita wartość portfela (USD):',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                Text(
                  '\$${totalPortfolioValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Historia dodanych inwestycji
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('investments')
                  .orderBy('timestamp',
                      descending: true) // Sortowanie od najnowszych
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

                    final asset = data['asset'] ?? 'Brak aktywa';
                    final exchange = data['exchange'] ?? 'Brak giełdy';
                    final price = data['price']?.toString() ?? '0.0';
                    final iconUrl = data['iconUrl'] ??
                        'https://via.placeholder.com/40'; // Domyślna ikona, jeśli brak
                    final exchangeIconUrl = data['exchangeIconUrl'] ??
                        'https://via.placeholder.com/40';

                    return Card(
                      elevation: 2,
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.network(
                              iconUrl,
                              width: 30,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                            const SizedBox(width: 5),
                            Image.network(
                              exchangeIconUrl,
                              width: 30,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                            ),
                          ],
                        ),
                        title: Text(asset),
                        subtitle: Text('Giełda: $exchange\nCena: \$${price}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteInvestment(investments[index].id, asset),
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {},
      //   backgroundColor: Colors.lightBlue,
      //   child: const Icon(Icons.add),
      // ),
    );
  }
}
