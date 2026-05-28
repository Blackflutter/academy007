import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EvolucaoChart extends StatelessWidget {
  final List<Map<String, dynamic>> historico;

  const EvolucaoChart({super.key, required this.historico});

  @override
  Widget build(BuildContext context) {
    if (historico.isEmpty) {
      return const SizedBox();
    }

    final spots = historico.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      final peso = (item['peso'] as num).toDouble();

      return FlSpot(index.toDouble(), peso);
    }).toList();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryNeon,
              barWidth: 3,
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
