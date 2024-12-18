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
  String? _selectedCryptoImage; // URL wybranej kryptowaluty
  String? _selectedExchangeImage; // URL wybranej giełdy

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
      // assets.forEach((asset) {
      //   print('Fetched asset: ${asset['name']} - Image: ${asset['image']}');
      // });
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
    // Usuń fokus ze wszystkich pól wejściowych
    FocusScope.of(context).unfocus();

    if (_selectedAsset == null ||
        _selectedExchange == null ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wypełnij wszystkie pola!")),
      );
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nie jesteś zalogowany!")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('investments')
          .add({
        'asset': _selectedAsset,
        'exchange': _selectedExchange,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inwestycja dodana pomyślnie!")),
      );

      setState(() {
        // Wyczyść pola i zresetuj zmienne
        _selectedAsset = null;
        _selectedExchange = null;
        _selectedCryptoImage = null; // Wyczyść ikonę kryptowaluty
        _selectedExchangeImage = null; // Wyczyść ikonę giełdy
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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wybierz kryptowalutę:',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    _buildCryptoSearchField(),
                    SizedBox(height: 20),
                    Text('Wybierz giełdę:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    _buildExchangeSearchField(),
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
  Widget _buildCryptoSearchField() {
    return TextField(
      controller: _cryptoController,
      decoration: InputDecoration(
        labelText: 'Wybierz kryptowalutę',
        border: OutlineInputBorder(),
        prefixIcon: _selectedCryptoImage != null
            ? Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.network(
                  _selectedCryptoImage!,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported),
                ),
              )
            : Icon(Icons.currency_bitcoin),
        suffixIcon: Icon(Icons.search),
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
              ),
              child: _buildCryptoSelectionModal(),
            );
          },
        );
      },
      readOnly: true,
    );
  }

  Widget _buildCryptoSelectionModal() {
    List<Map<String, dynamic>> filteredAssets = List.from(_allAssets);

    return StatefulBuilder(
      builder: (context, modalSetState) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.8, // Modal zajmuje 80% wysokości ekranu
            child: Column(
              children: [
                // Pasek wyszukiwania
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Szukaj kryptowaluty',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    autofocus: true,
                    onChanged: (query) {
                      modalSetState(() {
                        filteredAssets = _allAssets.where((crypto) {
                          final name = crypto['name']?.toLowerCase() ?? '';
                          final symbol = crypto['symbol']?.toLowerCase() ?? '';
                          return name.contains(query.toLowerCase()) ||
                              symbol.contains(query.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                ),
                // Lista wyników kryptowalut
                Expanded(
                  child: SingleChildScrollView(
                    child: filteredAssets.isEmpty
                        ? Center(child: Text('Brak wyników.'))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: filteredAssets.length,
                            itemBuilder: (context, index) {
                              final crypto = filteredAssets[index];
                              return ListTile(
                                leading: crypto['image'] != null
                                    ? Image.network(
                                        crypto['image'],
                                        width: 30,
                                        height: 30,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.image_not_supported),
                                      )
                                    : Icon(Icons.image_not_supported),
                                title:
                                    Text(crypto['symbol']?.toUpperCase() ?? ''),
                                subtitle: Text(crypto['name'] ?? ''),
                                onTap: () {
                                  setState(() {
                                    _selectedAsset = crypto['name'];
                                    _cryptoController.text =
                                        crypto['symbol']?.toUpperCase() ?? '';
                                    _selectedCryptoImage = crypto['image'];
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Pole TypeAhead dla giełd
  Widget _buildExchangeSearchField() {
    return TextField(
      controller: _exchangeController,
      decoration: InputDecoration(
        labelText: 'Wybierz giełdę',
        border: OutlineInputBorder(),
        prefixIcon: _selectedExchangeImage != null
            ? Padding(
                padding: const EdgeInsets.all(6.0),
                child: Image.network(
                  _selectedExchangeImage!,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image_not_supported),
                ),
              )
            : Icon(Icons.storefront),
        suffixIcon: Icon(Icons.search),
      ),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
              ),
              child: _buildExchangeSelectionModal(),
            );
          },
        );
      },
      readOnly: true,
    );
  }

  Widget _buildExchangeSelectionModal() {
    List<Map<String, dynamic>> filteredExchanges = List.from(_allExchanges);

    return StatefulBuilder(
      builder: (context, modalSetState) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.8, // Modal zajmuje 80% wysokości ekranu
            child: Column(
              children: [
                // Pasek wyszukiwania
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Szukaj giełdy',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    autofocus: true,
                    onChanged: (query) {
                      modalSetState(() {
                        filteredExchanges = _allExchanges.where((exchange) {
                          final name = exchange['name']?.toLowerCase() ?? '';
                          return name.contains(query.toLowerCase());
                        }).toList();
                      });
                    },
                  ),
                ),
                // Lista wyników giełd
                Expanded(
                  child: SingleChildScrollView(
                    child: filteredExchanges.isEmpty
                        ? Center(child: Text('Brak wyników.'))
                        : ListView.builder(
                            physics: BouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: filteredExchanges.length,
                            itemBuilder: (context, index) {
                              final exchange = filteredExchanges[index];
                              return ListTile(
                                leading: exchange['image'] != null
                                    ? Image.network(
                                        exchange['image'],
                                        width: 30,
                                        height: 30,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.image_not_supported),
                                      )
                                    : Icon(Icons.image_not_supported),
                                title: Text(exchange['name'] ?? ''),
                                onTap: () {
                                  setState(() {
                                    _selectedExchange = exchange['name'];
                                    _exchangeController.text =
                                        exchange['name'] ?? '';
                                    _selectedExchangeImage = exchange['image'];
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
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
