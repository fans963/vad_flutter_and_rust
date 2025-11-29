import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vad/src/provider/audio_process_providr.dart';
import 'package:vad/src/provider/chart_control_provider.dart';
import 'package:vad/src/provider/chart_paramater_provider.dart';
import 'package:vad/src/rust/api/audio_processor.dart';

class ChartWidget extends ConsumerWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(chartDataProvider);

    return Container(
      height: 500,
      padding: const EdgeInsets.all(16.0),
      child: chartDataAsync.when(
        data: (lineBars) => LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (LineBarSpot touchedSpot) {
                  return Colors.white.withOpacity(0.8);
                },
              ),
            ),
            minX: ref.watch(chartControlProvider).minX,
            maxX: ref.watch(chartControlProvider).maxX,
            minY: ref.watch(chartControlProvider).minY,
            maxY: ref.watch(chartControlProvider).maxY,
            lineBarsData: lineBars,
            titlesData: const FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 35.0),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 35.0),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading chart: $error')),
      ),
    );
  }
}
