import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';
import 'package:vad/src/signals/chart_control_signal.dart';
import 'package:vad/src/signals/chart_series_signal.dart';
import 'package:vad/src/rust/api/events/communicator_events.dart';
import 'package:vad/src/rust/api/types/chart.dart';
import 'package:vad/src/rust/api/types/events.dart';

class ChartWidget extends StatefulWidget {
  const ChartWidget({super.key});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartDataContainer {
  final LinkedHashMap<String, List<CommunicatorChart>> seriesData =
      LinkedHashMap();

  void addSeries(String key, CommunicatorChart chartData) {
    seriesData.putIfAbsent(key, () => []).add(chartData);
  }

  void removeSeries(String key) {
    seriesData.remove(key);
  }

  void removeChartByType(String key, DataType dataType) {
    final list = seriesData[key];
    if (list != null) {
      list.removeWhere((c) => c.dataType == dataType);
      if (list.isEmpty) seriesData.remove(key);
    }
  }

  void clearAll() {
    seriesData.clear();
  }

  List<String> getKeys() => seriesData.keys.toList();

  List<CommunicatorChart>? getCharts(String key) => seriesData[key];
}

class _ChartWidgetState extends State<ChartWidget> {
  StreamSubscription<ChartEvent>? _chartEventSubscription;
  final _containerKey = GlobalKey();
  final _ChartDataContainer _chartDataContainer = _ChartDataContainer();
  int _dataVersion = 0;

  @override
  void dispose() {
    onViewRangeChanged = null;
    _chartEventSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    onViewRangeChanged = _onViewRangeChanged;

    _chartEventSubscription = createChartEventStream().listen(
      (event) {
        switch (event) {
          case ChartEvent_AddChart():
            {
              _chartDataContainer.addSeries(event.chart.key, event.chart);
              chartSeriesManager.registerSeries(
                event.chart.key,
                event.chart.dataType,
              );
              _dataVersion++;
            }
          case ChartEvent_UpdateAllCharts():
            {
              _chartDataContainer.clearAll();
              for (final chart in event.charts) {
                _chartDataContainer.addSeries(chart.key, chart);
                chartSeriesManager.registerSeries(chart.key, chart.dataType);
              }
              _dataVersion++;
            }
          case ChartEvent_RemoveChart():
            {
              _chartDataContainer.removeChartByType(
                event.key,
                event.dataType,
              );
              chartSeriesManager.unregisterSeries(event.key, event.dataType);
              _dataVersion++;
            }
          case ChartEvent_RemoveAllCharts():
            {
              _chartDataContainer.clearAll();
              _dataVersion++;
            }
          case ChartEvent_UpdateMaxIndex():
            {
              chartMaxIndexSignal.value = event.maxIndex.toDouble();
              recomputeVisibleRanges();
            }
          case ChartEvent_UpdateYRange():
            {
              yAutoMinSignal.value = event.minY.toDouble();
              yAutoMaxSignal.value = event.maxY.toDouble();
              recomputeVisibleRanges();
            }
        }
        setState(() {});
      },
      onError: (error) => debugPrint('Chart event stream error: $error'),
      cancelOnError: false,
    );
  }

  void _onViewRangeChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    chartSeriesManager.versionSignal.value; // track series state changes
    final seriesList = _buildChartSeries();
    final xMin = xViewMinSignal.value;
    final xMax = xViewMaxSignal.value;
    final yMin = yViewMinSignal.value;
    final yMax = yViewMaxSignal.value;
    return SizedBox(
      key: _containerKey,
      height: 500,
      child: RepaintBoundary(
        child: SfCartesianChart(
          key: ValueKey(
              'chart_${xMin.toInt()}_${xMax.toInt()}_$_dataVersion'
              '_v${chartSeriesManager.versionSignal.value}',
            ),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerLowest,
          legend: Legend(
            isVisible: true,
            isResponsive: true,
            position: LegendPosition.bottom,
          ),
          primaryXAxis: NumericAxis(
            minimum: xViewMinSignal.value,
            maximum: xViewMaxSignal.value,
            rangePadding: ChartRangePadding.none,
            majorGridLines: const MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            plotBands: [
              PlotBand(
                isVisible: true,
                start: 0.0,
                end: 0.0,
                borderColor: Colors.red,
                borderWidth: 1,
              ),
            ],
          ),
          primaryYAxis: NumericAxis(
            minimum: yViewMinSignal.value,
            maximum: yViewMaxSignal.value,
            rangePadding: ChartRangePadding.none,
            majorGridLines: const MajorGridLines(width: 0),
          ),
          onLegendTapped: (legendTapArgs) {
            final rawName = legendTapArgs.series.name;
            if (rawName == null) return;
            // series name format: "$filePath ${dataType.name}"
            final lastSpace = rawName.lastIndexOf(' ');
            if (lastSpace == -1) return;
            final filePath = rawName.substring(0, lastSpace);
            final dtName = rawName.substring(lastSpace + 1);
            final dataType =
                DataType.values.firstWhere((d) => d.name == dtName);
            chartSeriesManager.select(filePath, dataType);
          },
          series: seriesList,
        ),
      ),
    );
  }

  List<CartesianSeries> _buildChartSeries() {
    final keys = _chartDataContainer.getKeys();

    final seriesList = <CartesianSeries>[];

    for (final key in keys) {
      final charts = _chartDataContainer.getCharts(key)!;

      for (final communicatorChart in charts) {
        final color = chartSeriesManager.getColor(
          key,
          communicatorChart.dataType,
        );
        final selected = chartSeriesManager.isSelected(
          key,
          communicatorChart.dataType,
        );
        final lineWidth = selected ? 1.5 : 0.4;
        final opacity = selected ? 1.0 : 0.7;

        switch (communicatorChart.dataType) {
          case DataType.zeroCrossingRate || DataType.energy:
            {
              seriesList.add(
                StepLineSeries<Point, double>(
                  name: '$key ${communicatorChart.dataType.name}',
                  dataSource: communicatorChart.chart,
                  xValueMapper: (Point point, _) => point.x,
                  yValueMapper: (Point point, _) => point.y,
                  color: color.withOpacity(opacity),
                  animationDuration: 0,
                  width: lineWidth,
                ),
              );
            }
          default:
            {
              seriesList.add(
                FastLineSeries<Point, double>(
                  name: '$key ${communicatorChart.dataType.name}',
                  dataSource: communicatorChart.chart,
                  xValueMapper: (Point point, _) => point.x,
                  yValueMapper: (Point point, _) => point.y,
                  color: color.withOpacity(opacity),
                  width: lineWidth,
                  animationDuration: 0,
                ),
              );
            }
        }
      }
    }
    return seriesList;
  }
}