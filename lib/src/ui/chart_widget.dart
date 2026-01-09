import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:vad/src/provider/chart_control_provider.dart';
import 'package:vad/src/provider/chart_paramater_provider.dart';

class ChartWidget extends ConsumerWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartDataAsync = ref.watch(chartDataProvider);
    final control = ref.watch(chartControlProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: chartDataAsync.when(
        data: (seriesData) => SfCartesianChart(
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          primaryXAxis: NumericAxis(
            minimum: control.minX,
            maximum: control.maxX,
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              dashArray: const [5, 5],
            ),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          primaryYAxis: NumericAxis(
            minimum: control.minY,
            maximum: control.maxY,
            majorGridLines: MajorGridLines(
              width: 0.5,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
              dashArray: const [5, 5],
            ),
            axisLine: const AxisLine(width: 0),
            labelStyle: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
              fontFamily: 'JetBrains Mono',
            ),
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            header: '',
            canShowMarker: false,
            textStyle: const TextStyle(fontFamily: 'JetBrains Mono'),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
          ),
          series: seriesData.map((data) {
            return AreaSeries<double, double>(
              dataSource: data.chartData.data,
              xValueMapper: (double val, int i) => data.chartData.index[i],
              yValueMapper: (double val, int i) => val,
              color: data.color.withValues(alpha: 0.3),
              borderColor: data.color,
              borderWidth: 2,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  data.color.withValues(alpha: 0.5),
                  data.color.withValues(alpha: 0.0),
                ],
              ),
              animationDuration: 1000,
              name: 'Audio Signal',
            );
          }).toList(),
        ),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 2,
              ),
              const SizedBox(height: 16),
              Text(
                'PROCESSING SIGNAL...',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 32),
                const SizedBox(height: 16),
                Text(
                  'SIGNAL INTERRUPT',
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 10,
                    color: Colors.redAccent.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
