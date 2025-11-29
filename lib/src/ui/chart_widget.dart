import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vad/src/provider/chart_paramater_provider.dart';

class ChartWidget extends ConsumerWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCharts = ref.watch(chartParameterProvider);
    // Widget implementation goes here
    return LineChart(
      LineChartData(
        lineBarsData: activeCharts.map((chart) {
          // Convert ChartDataParameter to LineChartBarData
          return LineChartBarData(spots: []);
        }).toList(),
      ),
    );
  }
}
