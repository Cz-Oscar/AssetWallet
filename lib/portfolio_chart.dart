import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'portfolio_data.dart';

class PortfolioChart extends StatelessWidget {
  final List<PortfolioData> portfolioData;

  const PortfolioChart(this.portfolioData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                "\$${value.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // Zapewnienie poprawnej daty na osi X
                if (value.toInt() >= 0 &&
                    value.toInt() < portfolioData.length) {
                  final date = portfolioData[value.toInt()].date;
                  return Text(
                    "${date.day}/${date.month}",
                    style: const TextStyle(fontSize: 10),
                  );
                } else {
                  return const Text('');
                }
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: portfolioData.map((data) {
              final index = portfolioData.indexOf(data);
              return FlSpot(index.toDouble(), data.userValue);
            }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.blueAccent],
            ),
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            barWidth: 3, // Grubość linii
          ),
          LineChartBarData(
            spots: portfolioData.map((data) {
              final index = portfolioData.indexOf(data);
              return FlSpot(index.toDouble(), data.marketValue);
            }).toList(),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Colors.green, Colors.lightGreen],
            ),
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
            barWidth: 3, // Grubość linii
          ),
        ],
        borderData: FlBorderData(
          show: true,
          border: const Border.symmetric(
            horizontal: BorderSide(color: Colors.black, width: 1),
          ),
        ),
      ),
    );
  }
}
