import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddInvestmentPage extends StatefulWidget {
  @override
  _AddInvestmentPageState createState() => _AddInvestmentPageState();
}

class _AddInvestmentPageState extends State<AddInvestmentPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _allAssets = [];
  List<String> _filteredAssets = [];
  String? _selectedAsset;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
    _searchController.addListener(_filterAssets);
  }

  Future<void> _fetchAssets() async {
    try {
      final assets = await ApiService().getAssets(); // Pobieranie z API
      setState(() {
        _allAssets = assets;
        _filteredAssets = assets;
      });
    } catch (e) {
      print('Błąd pobierania aktywów: $e');
    }
  }

  void _filterAssets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAssets = _allAssets
          .where((asset) => asset.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dodaj Inwestycję'),
      ),
      body: Column(
        children: [
          // Pole wyszukiwania
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Szukaj kryptowaluty',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          // Dynamiczna lista filtrowanych wyników
          Expanded(
            child: _filteredAssets.isEmpty
                ? Center(child: Text('Brak wyników'))
                : ListView.builder(
                    itemCount: _filteredAssets.length,
                    itemBuilder: (context, index) {
                      final asset = _filteredAssets[index];
                      return ListTile(
                        title: Text(asset),
                        onTap: () {
                          setState(() {
                            _selectedAsset = asset; // Ustaw wybraną wartość
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Wybrano: $asset')),
                          );
                        },
                      );
                    },
                  ),
          ),
          // Wyświetlenie wybranego aktywa
          if (_selectedAsset != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Wybrano: $_selectedAsset',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
