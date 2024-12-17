import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

class AddInvestmentPage extends StatefulWidget {
  @override
  _AddInvestmentPageState createState() => _AddInvestmentPageState();
}

class _AddInvestmentPageState extends State<AddInvestmentPage> {
  List<Map<String, dynamic>> _allAssets = [];
  List<Map<String, dynamic>> _allExchanges = [];

  String? _selectedAsset;
  String? _selectedExchange;
  final TextEditingController _priceController =
      TextEditingController(); //price

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCryptos();
    _fetchExchanges();
  }

  Future<void> _fetchExchanges() async {
    try {
      final exchanges = await ApiService().getExchanges();
      setState(() {
        _allExchanges = exchanges;
      });
    } catch (e) {
      print("Błąd pobierania giełd: $e");
    }
  }

  Future<void> _fetchCryptos() async {
    try {
      final assets = await ApiService().getAssetsWithLogos();
      assets.forEach((asset) => ());
      setState(() {
        _allAssets = assets;
        _isLoading = false;
      });
    } catch (e) {
      print('Błąd pobierania kryptowalut: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dodaj Inwestycję'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wybierz kryptowalutę:', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 5),
                  _buildCryptoTypeAheadField(),
                  SizedBox(height: 20),
                  Text('Wybierz giełdę:', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 5),
                  _buildExchangeTypeAheadField(),
                  SizedBox(
                    height: 20,
                  ),
                  Text('Podaj cene zakupu: ', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 5),
                  _buildPriceFieldWithToolbar(),
                ],
              ),
            ),
    );
  }

  /// Pole TypeAhead dla kryptowalut
  Widget _buildCryptoTypeAheadField() {
    return TypeAheadField<Map<String, dynamic>>(
      suggestionsCallback: (pattern) {
        return _allAssets.where((crypto) {
          final name = crypto['name']?.toLowerCase() ?? '';
          final symbol = crypto['symbol']?.toLowerCase() ?? '';
          return name.contains(pattern.toLowerCase()) ||
              symbol.contains(pattern.toLowerCase());
        }).toList();
      },
      itemBuilder: (context, suggestion) {
        final imageUrl = suggestion['image']; // Używamy właściwego klucza
        return ListTile(
          leading: (imageUrl != null && imageUrl.isNotEmpty)
              ? Image.network(
                  imageUrl,
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error), // Obsługa błędu ładowania obrazu
                )
              : Icon(Icons.image_not_supported),
          title: Text(suggestion['symbol']?.toUpperCase() ?? ''),
          subtitle: Text(suggestion['name'] ?? ''),
        );
      },
      onSelected: (suggestion) {
        setState(() {
          _selectedAsset = suggestion['name'];
        });
        print("Wybrano kryptowalutę: ${suggestion['name']}");
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Szukaj kryptowaluty',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        );
      },
    );
  }

  /// Pole TypeAhead dla giełd
  Widget _buildExchangeTypeAheadField() {
    return TypeAheadField<Map<String, dynamic>>(
      suggestionsCallback: (pattern) {
        return _allExchanges.where((exchange) {
          final name = exchange['name']?.toLowerCase() ?? '';
          return name.contains(pattern.toLowerCase());
        }).toList();
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: suggestion['image'] != null &&
                  (suggestion['image'] as String).isNotEmpty
              ? Image.network(
                  suggestion['image'],
                  width: 30,
                  height: 30,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.error),
                )
              : Icon(Icons.image_not_supported),
          title: Text(suggestion['name'] ?? ''),
        );
      },
      onSelected: (suggestion) {
        setState(() {
          _selectedExchange = suggestion['name'];
        });
        print("Wybrano giełdę: ${suggestion['name']}");
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Szukaj giełdy',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
        );
      },
    );
  }

  FocusNode _priceFocusNode = FocusNode();

  Widget _buildPriceFieldWithToolbar() {
    return Column(
      children: [
        TextField(
          controller: _priceController,
          focusNode: _priceFocusNode,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: "Podaj cenę: ",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            suffixText: 'USD',
            suffixStyle: TextStyle(color: Colors.grey),
          ),
        ),
        CupertinoButton(
          child: Text("Gotowe"),
          onPressed: () {
            FocusScope.of(context).unfocus(); // Schowanie klawiatury
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}
