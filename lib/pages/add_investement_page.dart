import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final TextEditingController _cryptoController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();
  final FocusNode _cryptoFocusNode = FocusNode();
  final FocusNode _exchangeFocusNode = FocusNode();
  bool _cryptoFieldActive = false;
  bool _exchangeFieldActive = false;

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

  Future<void> _addInvestmentToFirestore() async {
    FocusScope.of(context).unfocus();

    if (_selectedAsset == null ||
        _selectedExchange == null ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Wypełnij wszystkie pola!")),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nie jesteś zalogowany!")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users') // Kolekcja użytkowników
          .doc(user.uid) // Dokument użytkownika (po UID)
          .collection('investments') // Podkolekcja inwestycji
          .add({
        'asset': _selectedAsset,
        'exchange': _selectedExchange,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Inwestycja dodana pomyślnie!")),
      );

      setState(() {
        _selectedAsset = null;
        _selectedExchange = null;
        _priceController.clear();
        _cryptoController.clear();
        _exchangeController.clear();
      });
    } catch (e) {
      print("Błąd zapisu do Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd zapisu: $e")),
      );
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
          : SingleChildScrollView(
              // Dodaj przewijanie
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wybierz kryptowalutę:',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    _buildCryptoTypeAheadField(),
                    SizedBox(height: 20),
                    Text('Wybierz giełdę:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    _buildExchangeTypeAheadField(),
                    SizedBox(height: 20),
                    Text('Podaj cenę zakupu:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    _buildPriceFieldWithToolbar(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // Zamknij klawiaturę
                        _addInvestmentToFirestore();
                      },
                      child: Text("Dodaj inwestycję do portfela"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Pole TypeAhead dla kryptowalut
  Widget _buildCryptoTypeAheadField() {
    return TypeAheadField<Map<String, dynamic>>(
      controller: _cryptoController,
      focusNode: _cryptoFocusNode,
      hideOnEmpty: true,
      suggestionsCallback: (pattern) {
        return _allAssets.where((crypto) {
          final name = crypto['name']?.toLowerCase() ?? '';
          final symbol = crypto['symbol']?.toLowerCase() ?? '';
          return name.contains(pattern.toLowerCase()) ||
              symbol.contains(pattern.toLowerCase());
        }).toList();
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: suggestion['image'] != null
              ? Image.network(suggestion['image'], width: 30, height: 30)
              : Icon(Icons.image_not_supported),
          title: Text(suggestion['symbol']?.toUpperCase() ?? ''),
          subtitle: Text(suggestion['name'] ?? ''),
        );
      },
      onSelected: (suggestion) {
        setState(() {
          _selectedAsset = suggestion['name'];
          _cryptoController.text = suggestion['symbol']?.toUpperCase() ?? '';
        });
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: _cryptoFocusNode.hasFocus ? false : true,
          decoration: InputDecoration(
            labelText: 'Wybierz kryptowalutę',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            suffixIcon: _cryptoController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _cryptoController.clear();
                        _selectedAsset = null;
                      });
                    },
                  )
                : null,
          ),
        );
      },
    );
  }

  /// Pole TypeAhead dla giełd
  Widget _buildExchangeTypeAheadField() {
    return TypeAheadField<Map<String, dynamic>>(
      controller: _exchangeController,
      focusNode: _exchangeFocusNode,
      hideOnEmpty: true,
      suggestionsCallback: (pattern) {
        return _allExchanges.where((exchange) {
          final name = exchange['name']?.toLowerCase() ?? '';
          return name.contains(pattern.toLowerCase());
        }).toList();
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: suggestion['image'] != null
              ? Image.network(suggestion['image'], width: 30, height: 30)
              : Icon(Icons.image_not_supported),
          title: Text(suggestion['name'] ?? ''),
        );
      },
      onSelected: (suggestion) {
        setState(() {
          _selectedExchange = suggestion['name'];
          _exchangeController.text = suggestion['name'] ?? '';
        });
      },
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          readOnly: _exchangeFocusNode.hasFocus ? false : true,
          decoration: InputDecoration(
            labelText: 'Wybierz giełdę',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            suffixIcon: _exchangeController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _exchangeController.clear();
                        _selectedExchange = null;
                      });
                    },
                  )
                : null,
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
