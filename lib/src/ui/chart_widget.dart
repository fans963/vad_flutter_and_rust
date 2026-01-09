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

    return Container(
      height: 500,
      padding: const EdgeInsets.all(16.0),
      child: chartDataAsync.when(
        data: (seriesData) => SfCartesianChart(
          primaryXAxis: NumericAxis(
            minimum: control.minX,
            maximum: control.maxX,
            majorGridLines: const MajorGridLines(width: 0.5),
            title: const AxisTitle(text: 'Index'),
          ),
          primaryYAxis: NumericAxis(
            minimum: control.minY,
            maximum: control.maxY,
            majorGridLines: const MajorGridLines(width: 0.5),
            title: const AxisTitle(text: 'Amplitude'),
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            header: '',
            canShowMarker: false,
          ),
          series: seriesData.map((data) {
            return FastLineSeries<double, double>(
              dataSource: data.chartData.data,
              xValueMapper: (double val, int i) => data.chartData.index[i],
              yValueMapper: (double val, int i) => val,
              color: data.color,
              animationDuration: 0,
              name: 'Audio Signal',
            );
          }).toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading chart: $error')),
      ),
    );
  }
}
