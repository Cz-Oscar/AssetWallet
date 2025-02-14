import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_asset_wallet/portfolio_data.dart';

class PortfolioChart extends StatelessWidget {
  final List<PortfolioData> chartData;

  const PortfolioChart(this.chartData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'Obecnie nie masz żadnych inwestycji. Dodaj pierwszą!',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    // Pobierz minimalną i maksymalną wartość w danych
    final minValue = chartData
        .map((data) => data.userValue)
        .followedBy(chartData.map((data) => data.marketValue))
        .reduce((a, b) => a < b ? a : b);

    final maxValue = chartData
        .map((data) => data.userValue)
        .followedBy(chartData.map((data) => data.marketValue))
        .reduce((a, b) => a > b ? a : b);

    // Oblicz dynamiczny zakres wartości i dostosowanie interwału
    final range = maxValue - minValue;
    final adjustedMinY =
        (minValue - range * 0.1).floorToDouble(); // Zaokrąglenie w dół
    final adjustedMaxY =
        (maxValue + range * 0.1).ceilToDouble(); // Zaokrąglenie w górę
    final interval = ((adjustedMaxY - adjustedMinY) / 5).ceilToDouble();

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.white,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                'Wartość portfela [\$]',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                interval: interval, // Dynamiczny interwał
                getTitlesWidget: (value, meta) {
                  if (value == adjustedMinY || value == adjustedMaxY) {
                    return Container(); // Nie wyświetlaj wartości
                  }

                  return Text(
                    '\$${value.toStringAsFixed(0)}', // Zaokrąglona wartość
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                'Data zakupu',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= chartData.length)
                    return Container();

                  // Pobierz unikalne daty jako indeksy osi X
                  final DateTime date = chartData[value.toInt()].date;
                  String formattedDate = '${date.day}/${date.month}';

                  return Text(
                    formattedDate,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval:
                interval, // Dynamiczna siatka dopasowana do interwału
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.deepOrange, width: 2),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: chartData
                  .asMap()
                  .entries
                  .map((entry) => FlSpot(
                        entry.key.toDouble(),
                        entry.value.userValue,
                      ))
                  .toList(),
              isCurved: false,
              gradient: const LinearGradient(
                colors: [Colors.blueGrey, Colors.blueGrey],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: chartData
                  .asMap()
                  .entries
                  .map((entry) => FlSpot(
                        entry.key.toDouble(),
                        entry.value.marketValue,
                      ))
                  .toList(),
              isCurved: false,
              gradient: LinearGradient(
                colors: [Colors.deepOrange[300]!, Colors.deepOrange[300]!],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
          minX: 0,
          maxX: (chartData.length - 1).toDouble(),
          minY: adjustedMinY, // Dynamiczny zakres
          maxY: adjustedMaxY, // Dynamiczny zakres
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 10,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final date = chartData[index].date;
                  final formattedDate =
                      '${date.day}/${date.month}/${date.year}';
                  final isUserValue = spot.barIndex == 0;

                  return LineTooltipItem(
                    '$formattedDate\n${spot.y.toStringAsFixed(2)}',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: isUserValue
                            ? '\nWartość inwestycji'
                            : '\nObecna Wartość',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),
        ),
      ),
    );
  }
}
