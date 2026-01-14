// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:vad/src/provider/chart_control_provider.dart';
// import 'package:vad/src/provider/chart_paramater_provider.dart';

// class ChartWidget extends ConsumerWidget {
//   const ChartWidget({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final chartDataAsync = ref.watch(chartDataProvider);
//     final control = ref.watch(chartControlProvider);

//     return Container(
//       height: 500,
//       padding: const EdgeInsets.all(16.0),
//       child: chartDataAsync.when(
//         data: (seriesList) {
//           if (seriesList.isEmpty) {
//             return const Center(child: Text('No data to display'));
//           }

//           final lineBarsData = seriesList.asMap().entries.map((entry) {
//             final i = entry.key;
//             final series = entry.value;
//             final chartParam = ref.read(chartParameterProvider)[i];
            
//             final double xStart = chartParam.index.$1.toDouble();
//             final double xEnd = chartParam.index.$2.toDouble();
//             final double originalRange = xEnd - xStart;
//             final int sampledCount = series.chartData.data.length;
            
//             // 计算步长：如果采样后只有1个点或没有点，步长默认为1
//             final double step = sampledCount > 1 ? originalRange / (sampledCount - 1) : 1.0;

//             final spots = series.chartData.data.asMap().entries.map((e) {
//               final double x = xStart + (e.key * step);
//               return FlSpot(x, e.value.toDouble());
//             }).toList();

//             return LineChartBarData(
//               spots: spots,
//               isCurved: false,
//               color: series.color,
//               barWidth: 1,
//               isStrokeCapRound: true,
//               dotData: const FlDotData(show: false),
//               belowBarData: BarAreaData(show: false),
//             );
//           }).toList();

//           return LineChart(
//             LineChartData(
//               lineBarsData: lineBarsData,
//               minX: control.minX,
//               maxX: control.maxX,
//               minY: control.minY,
//               maxY: control.maxY,
//               titlesData: const FlTitlesData(
//                 show: true,
//                 bottomTitles: AxisTitles(
//                   axisNameWidget: Text('数据点序号'),
//                   sideTitles: SideTitles(showTitles: true, reservedSize: 30),
//                 ),
//                 leftTitles: AxisTitles(
//                   axisNameWidget: Text('数值'),
//                   sideTitles: SideTitles(showTitles: true, reservedSize: 40),
//                 ),
//                 topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               ),
//               gridData: const FlGridData(show: true),
//               borderData: FlBorderData(show: true),
//               lineTouchData: const LineTouchData(enabled: false), // Disable touch for performance
//             ),
//           );
//         },
//         loading: () => const Center(child: CircularProgressIndicator()),
//         error: (error, stack) =>
//             Center(child: Text('Error loading chart: $error')),
//       ),
//     );
//   }
// }
