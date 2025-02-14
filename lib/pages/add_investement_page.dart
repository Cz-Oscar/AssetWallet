import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  String? _selectedCryptoImage;
  String? _selectedExchangeImage;
  DateTime? _selectedDate; // date variable

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cryptoController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();

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

  Future<String?> _fetchCryptoId(String symbol) async {
    try {
      final assets = await ApiService().getAssetsWithLogos();
      final match = assets.firstWhere(
        (asset) =>
            asset['symbol'].toString().toLowerCase() == symbol.toLowerCase(),
        orElse: () => {}, // Zwraca pustą mapę zamiast null
      );

      return match.isNotEmpty
          ? match['id']?.toString()
          : null; // Sprawdza, czy mapa nie jest pusta
    } catch (e) {
      print("Błąd podczas pobierania ID kryptowaluty: $e");
      return null;
    }
  }

  Future<void> _addInvestmentToFirestore() async {
    FocusScope.of(context).unfocus();

    // Sprawdź, czy wszystkie pola zostały wypełnione
    if (_selectedAsset == null ||
        _cryptoController.text.isEmpty ||
        _selectedExchange == null ||
        _priceController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedDate == null) {
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

    // Pobierz ID kryptowaluty na podstawie symbolu
    final String symbol = _cryptoController.text.toLowerCase();
    // print("Zawartość _allAssets: ${_allAssets.take(10)}");

    final selectedCrypto = _allAssets.firstWhere(
      (crypto) => crypto['symbol']?.toLowerCase() == symbol,
      orElse: () => {}, // Zwraca pustą mapę, jeśli brak dopasowania
    );

    if (selectedCrypto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("Nie znaleziono ID dla symbolu ${_cryptoController.text}"),
        ),
      );
      return;
    }

    final cryptoId = selectedCrypto['id'] ?? 'unknown';

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Sprawdź, czy dokument użytkownika istnieje
      final userSnapshot = await userDoc.get();
      if (!userSnapshot.exists) {
        print('Dokument użytkownika nie istnieje. Tworzenie nowego...');
        await userDoc.set({
          'email': user.email,
          'lastActiveAt':
              FieldValue.serverTimestamp(), // Ustawienie lastActiveAt
          'default_value': 0.0, // Domyślna wartość
        });
      } else {
        Map<String, dynamic> userData = userSnapshot.data() ?? {};

        // Jeśli dokument już istnieje, zaktualizuj pole `lastActiveAt`
        print('Aktualizowanie lastActiveAt...');
        await userDoc.update({
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
      // Dodaj inwestycję do Firestore
      final investmentData = {
        'asset': _selectedAsset,
        'symbol': _cryptoController.text,
        'id': cryptoId, // Zapisujemy ID
        'exchange': _selectedExchange,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'date': Timestamp.fromDate(_selectedDate!),
        'timestamp': FieldValue.serverTimestamp(),
      };

      await userDoc.collection('investments').add(investmentData);
      print("Dodano inwestycję i zaktualizowano lastActiveAt.");

      // Sprawdź i zaktualizuj `default_value`, jeśli nie istnieje
      if (!userSnapshot.exists ||
          userSnapshot.data()?['default_value'] == null) {
        double defaultValue = 0.0;

        QuerySnapshot investmentsSnapshot =
            await userDoc.collection('investments').get();

        for (var doc in investmentsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          double price = (data['price'] ?? 0.0).toDouble();
          double amount = (data['amount'] ?? 0.0).toDouble();
          defaultValue += price * amount;
        }

        // Zapisz `default_value` w dokumencie użytkownika
        await userDoc.update({'default_value': defaultValue});
        print(
            "Zaktualizowano default_value dla użytkownika ${user.uid}: $defaultValue");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inwestycja dodana pomyślnie!")),
      );

      // Resetuj pola formularza
      setState(() {
        _selectedAsset = null;
        _selectedExchange = null;
        _selectedCryptoImage = null; // Reset obrazka kryptowaluty
        _selectedExchangeImage = null; // Reset obrazka giełdy
        _priceController.clear();
        _amountController.clear();
        _cryptoController.clear(); // Reset kontrolera kryptowaluty
        _exchangeController.clear(); // Reset kontrolera giełdy
        _selectedDate = null;
      });
    } catch (e) {
      print("Błąd zapisu do Firestore: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd zapisu: $e")),
      );
    }
  }

  Future<void> _updateDefaultPortfolioValue(String userId) async {
    try {
      double totalValue = 0.0;

      // Pobierz inwestycje z Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('investments')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        double price = (data['price'] ?? 0.0).toDouble();
        double amount = (data['amount'] ?? 0.0).toDouble();

        totalValue += price * amount;
      }

      // Zapisz `totalValue` jako `default_value`
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'default_value': totalValue,
      });

      print(
          "Zaktualizowano default_value dla użytkownika $userId: $totalValue");
    } catch (e) {
      print("Błąd podczas aktualizacji default_value: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dodaj Inwestycję'),
        backgroundColor: Colors.lightBlue,
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
                    Text('Podaj ilość:',
                        style: TextStyle(fontSize: 16)), // Zamieniono kolejność
                    SizedBox(height: 5),
                    _buildAmountField(),
                    SizedBox(height: 20),
                    Text('Podaj cenę zakupu:', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 5),
                    _buildPriceFieldWithToolbar(),
                    SizedBox(height: 20),
                    SizedBox(height: 5),
                    _buildDatePickerField(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addInvestmentToFirestore,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30.0), // Zaokrąglone rogi
                        ),
                        backgroundColor:
                            Colors.lightBlue, // Dopasowany kolor do nav bara
                        elevation: 5, // Efekt cienia
                        shadowColor: Colors.black54,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add,
                              color: Colors.deepOrange[
                                  300]), // Dopasowany pomarańczowy kolor
                          SizedBox(width: 8),
                          Text(
                            "Dodaj inwestycję do portfela",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.deepOrange[
                                  300], // Dopasowany pomarańczowy kolor
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Podaj ilość',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.add_circle_outline),
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
            labelText: "Podaj cenę zakupu:",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.attach_money),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                'USD',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          onChanged: (value) {
            // Zamiana przecinka na kropkę
            String updatedValue = value.replaceAll(',', '.');

            // Walidacja liczby
            if ('.'.allMatches(updatedValue).length > 1) {
              updatedValue = updatedValue.substring(0, updatedValue.length - 1);
            }

            _priceController.text = updatedValue;
            _priceController.selection = TextSelection.fromPosition(
              TextPosition(offset: _priceController.text.length),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _selectedDate != null
                ? 'Wybrana data: ${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
                : 'Wybierz datę inwestycji:',
            style: TextStyle(fontSize: 16),
          ),
        ),
        IconButton(
          icon: Icon(Icons.calendar_today),
          onPressed: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
            );

            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
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
