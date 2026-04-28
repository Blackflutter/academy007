import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EvolucaoChart extends StatelessWidget {
  final List<Map<String, dynamic>> historico;

  const EvolucaoChart({super.key, required this.historico});

  @override
  Widget build(BuildContext context) {
    if (historico.isEmpty) {
      return const Center(child: Text("Sem dados de evolução ainda."));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: historico.asMap().entries.map((e) {
                return FlSpot(
                  e.key.toDouble(),
                  (e.value['peso'] as num).toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: AppTheme.primaryNeon,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryNeon.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
