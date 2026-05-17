import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:vad/src/signals/chart_control_signal.dart';
import 'package:vad/src/signals/chart_series_signal.dart';
import 'package:vad/src/signals/audio_player_signal.dart';
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
  final _ChartDataContainer _chartDataContainer = _ChartDataContainer();
  final _dataVersion = signal(0);

  @override
  void dispose() {
    _chartEventSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _chartEventSubscription = createChartEventStream().listen(
      (event) {
        switch (event) {
          case ChartEvent_AddChart():
            _chartDataContainer.addSeries(event.chart.key, event.chart);
            chartSeriesManager.registerSeries(
              event.chart.key,
              event.chart.dataType,
            );
            _dataVersion.value++;
          case ChartEvent_UpdateAllCharts():
            _chartDataContainer.clearAll();
            for (final chart in event.charts) {
              _chartDataContainer.addSeries(chart.key, chart);
              chartSeriesManager.registerSeries(chart.key, chart.dataType);
            }
            _dataVersion.value++;
          case ChartEvent_RemoveChart():
            _chartDataContainer.removeChartByType(event.key, event.dataType);
            chartSeriesManager.unregisterSeries(event.key, event.dataType);
            _dataVersion.value++;
          case ChartEvent_RemoveAllCharts():
            _chartDataContainer.clearAll();
            _dataVersion.value++;
          case ChartEvent_UpdateMaxIndex():
            chartMaxIndexSignal.value = event.maxIndex.toDouble();
            recomputeVisibleRanges();
          case ChartEvent_UpdateYRange():
            yAutoMinSignal.value = event.minY.toDouble();
            yAutoMaxSignal.value = event.maxY.toDouble();
            recomputeVisibleRanges();
          case ChartEvent_UpdatePlaybackState():
            updatePlaybackState(
              event.isPlaying,
              event.position,
              event.duration,
            );
        }
      },
      onError: (error) => debugPrint('Chart event stream error: $error'),
      cancelOnError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      _dataVersion.value;
      chartSeriesManager.versionSignal.value;
      xViewMinSignal.value;
      xViewMaxSignal.value;
      yViewMinSignal.value;
      yViewMaxSignal.value;

      final seriesList = _buildChartSeries();
      final xMin = xViewMinSignal.value;
      final xMax = xViewMaxSignal.value;

      return SizedBox(
        height: 500,
        child: RepaintBoundary(
          child: SfCartesianChart(
            key: ValueKey('chart_${_dataVersion.value}'),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            legend: Legend(
              isVisible: true,
              isResponsive: true,
              toggleSeriesVisibility: false,
              position: LegendPosition.bottom,
            ),
            primaryXAxis: NumericAxis(
              minimum: xMin,
              maximum: xMax,
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
            series: seriesList,
          ),
        ),
      );
    });
  }

  List<CartesianSeries> _buildChartSeries() {
    final keys = _chartDataContainer.getKeys();

    final seriesList = <CartesianSeries>[];

    for (final key in keys) {
      final charts = _chartDataContainer.getCharts(key)!;

      for (final communicatorChart in charts) {
        if (!chartSeriesManager.isVisible(key, communicatorChart.dataType)) {
          continue;
        }
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
          case DataType.vad:
            seriesList.add(
              AreaSeries<Point, double>(
                name: '$key ${communicatorChart.dataType.name}',
                dataSource: communicatorChart.chart,
                xValueMapper: (p, _) => p.x,
                yValueMapper: (p, _) => p.y,
                color: Colors.green.withOpacity(0.25),
                borderColor: Colors.green.withOpacity(0.6),
                borderWidth: 1,
                animationDuration: 0,
              ),
            );
          default:
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
    return seriesList;
  }
}
