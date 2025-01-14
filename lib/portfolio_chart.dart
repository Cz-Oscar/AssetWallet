import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_asset_wallet/portfolio_data.dart';

class PortfolioChart extends StatelessWidget {
  final List<PortfolioData> chartData;

  const PortfolioChart(this.chartData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pobierz minimalną i maksymalną wartość w danych
    final minValue = chartData
        .map((data) => data.userValue)
        .followedBy(chartData.map((data) => data.marketValue))
        .reduce((a, b) => a < b ? a : b);

    final maxValue = chartData
        .map((data) => data.userValue)
        .followedBy(chartData.map((data) => data.marketValue))
        .reduce((a, b) => a > b ? a : b);

    // Oblicz zakres danych
    final range = maxValue - minValue;

    // Dynamiczne wartości dla osi Y
    final minY = (minValue - range * 0.1).clamp(0.0, double.infinity);
    final maxY = maxValue + range * 0.1;

    // Odstęp osi Y
    final interval = ((maxY - minY) / 4).ceilToDouble();

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      child: LineChart(
        LineChartData(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                'Portfolio Value [\$]',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '\$${value.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 12, color: Color.fromARGB(255, 0, 0, 0)),
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                'Date',
                style: TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              axisNameSize: 20,
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    final date = chartData[index].date;
                    return Text(
                      '${date.day}/${date.month}',
                      style: const TextStyle(
                          fontSize: 12, color: Color.fromARGB(255, 0, 0, 0)),
                    );
                  }
                  return const Text('');
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
            // Siatka wyłączona
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
                color: const Color.fromARGB(255, 224, 113, 3).withOpacity(0.5),
                width: 2),
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
                colors: [Colors.blue, Colors.blueAccent],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: false,
                gradient: LinearGradient(
                  colors: [Colors.blue.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
              gradient: const LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: false,
                gradient: LinearGradient(
                  colors: [Colors.green.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minX: 0,
          maxX: (chartData.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding:
                  const EdgeInsets.all(8), // Padding wewnątrz tooltipa
              tooltipMargin: 10, // Odległość tooltipa od punktu
              getTooltipItems: (touchedSpots) {
                // Lista wszystkich punktów dotkniętych, więc dla każdego punktu tworzymy tooltip
                return touchedSpots.map((spot) {
                  // Pobieramy datę z chartData
                  final index = spot.x.toInt();
                  final date = chartData[index].date;
                  final formattedDate =
                      '${date.day}/${date.month}/${date.year}'; // Formatujemy datę

                  // Rozróżniamy, która linia to 'User Value', a która to 'Market Value'
                  final isUserValue = spot.barIndex == 0;

                  return LineTooltipItem(
                    '$formattedDate\n${spot.y.toStringAsFixed(2)}', // Data i wartość Y
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: isUserValue ? '\nUser Value' : '\nMarket Value',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true, // Włączenie dotyku na wykresie
          ),
        ),
      ),
    );
  }
}
