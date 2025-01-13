// import 'package:flutter/material.dart';
// import 'package:flutter_asset_wallet/portfolio_chart.dart';
// import 'package:flutter_asset_wallet/portfolio_data.dart';
// import 'portfolio_page.dart';

// class ChartsPage extends StatefulWidget {
//   final double totalPortfolioValue;
//   final double currentPortfolioValue;

//   const ChartsPage({
//     Key? key,
//     required this.totalPortfolioValue,
//     required this.currentPortfolioValue,
//   }) : super(key: key);

//   @override
//   State<ChartsPage> createState() => _ChartsPageState();
// }

// class _ChartsPageState extends State<ChartsPage> {
//   List<PortfolioData> _chartData = [];

//   @override
//   void initState() {
//     super.initState();
//     _generateChartData();
//   }

//   void _generateChartData() {
//     // Generowanie danych dla ostatnich 7 dni
//     final now = DateTime.now();
//     _chartData = List.generate(7, (index) {
//       final date = now.subtract(Duration(days: 6 - index));
//       // Dane przykładowe, bazujące na istniejących wartościach portfela
//       final userValue = widget.totalPortfolioValue - index * 10; // Zakup
//       final marketValue = widget.currentPortfolioValue - index * 15; // Rynek
//       return PortfolioData(date, userValue, marketValue);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Charts'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             const Text(
//               'Zmiany wartości portfela w ostatnich 7 dniach',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(
//               height: 16,
//             ),
//             Expanded(
//               child: PortfolioChart(_chartData),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_asset_wallet/portfolio_chart.dart';
import 'package:flutter_asset_wallet/portfolio_data.dart';

class ChartsPage extends StatelessWidget {
  final double totalPortfolioValue;
  final double currentPortfolioValue;

  const ChartsPage({
    Key? key,
    required this.totalPortfolioValue,
    required this.currentPortfolioValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generowanie danych dla wykresu (przykład na 7 dni)
    final List<PortfolioData> chartData = List.generate(7, (index) {
      final date = DateTime.now().subtract(Duration(days: 6 - index));
      final userValue = totalPortfolioValue -
          index * 10; // Przykład (wartość portfela na podstawie zakupu)
      final marketValue = currentPortfolioValue -
          index * 15; // Przykład (wartość portfela na podstawie rynku)
      return PortfolioData(date, userValue, marketValue);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Zmiany wartości portfela w ostatnich 7 dniach',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: PortfolioChart(chartData),
            ),
          ],
        ),
      ),
    );
  }
}
