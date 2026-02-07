import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:signals/signals_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';
import 'package:vad/src/signals/chart_control_signal.dart';
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

  void clearAll() {
    seriesData.clear();
  }

  List<String> getKeys() => seriesData.keys.toList();

  List<CommunicatorChart>? getCharts(String key) => seriesData[key];
}

class _ChartWidgetState extends State<ChartWidget> {
  StreamSubscription<ChartEvent>? _chartEventSubscription;
  final _containerKey = GlobalKey();
  double? _lastWidth;
  late final _ChartDataContainer _chartDataContainer = _ChartDataContainer();
  double minXAxis = 0.0;
  double maxXAxis = 1000000.0;

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
            {
              _chartDataContainer.addSeries(event.chart.key, event.chart);
              // debugPrint(
              //   "Received ChartEvent_AddChart: ${event.chart.key}, points: ${event.chart.chart.length}",
              // );
              setState(() {});
            }
          case ChartEvent_UpdateAllCharts():
            {
              _chartDataContainer.clearAll();
              for (final chart in event.charts) {
                _chartDataContainer.addSeries(chart.key, chart);
              }
              // debugPrint(
              //   "Received ChartEvent_UpdateAllCharts: total charts: ${event.charts.length}",
              // );
              setState(() {});
            }
          case ChartEvent_RemoveChart():
            {
              _chartDataContainer.removeSeries(event.key);
              // debugPrint("Removed chart: ${event.key}");
              setState(() {});
            }
          case ChartEvent_RemoveAllCharts():
            {
              _chartDataContainer.clearAll();
              // debugPrint("Removed all charts");
              setState(() {});
            }
        }
      },
      onError: (error) => debugPrint('Chart event stream error: $error'),
      cancelOnError: false,
    );

  }

  void _onSizeChanged(Size size) {
    if (size.width != _lastWidth) {
      _lastWidth = size.width;
      _updateEnginePoints(size.width);
    }
  }

  Future<void> _updateEnginePoints(double width) async {
    final engine = await audioProcessorEngine.engine();
    await engine.setDownSamplePointsNum(pointsNum: BigInt.from(width.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    final seriesList = _buildChartSeries();

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _onSizeChanged(constraints.biggest),
        );
        return SizedBox(
          key: _containerKey,
          height: 500,
          // padding: const EdgeInsets.all(10.0),
          child: RepaintBoundary(
            child: SfCartesianChart(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLowest,
              legend: Legend(
                isVisible: true,
                isResponsive: true,
                position: LegendPosition.bottom,
              ),
              zoomPanBehavior: ZoomPanBehavior(
                enablePinching: true,
                enablePanning: true,
                enableMouseWheelZooming: true,
                enableSelectionZooming: true,
                zoomMode: ZoomMode.x,
              ),
              primaryXAxis: NumericAxis(
                name: 'primaryXAxis',
                minimum: minXAxis,
                maximum: maxXAxis,
              ),
              primaryYAxis: const NumericAxis(
                name: 'primaryYAxis',
                minimum: -0.5,
                maximum: 100.0,
              ),
              onActualRangeChanged: (ActualRangeChangedArgs rangeChangedArgs) {
                if (rangeChangedArgs.axisName == 'primaryXAxis') {
                  final minX = (rangeChangedArgs.visibleMin as num).toDouble();
                  final maxX = (rangeChangedArgs.visibleMax as num).toDouble();

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final engine = await audioProcessorEngine.engine();
                    await engine.setIndexRange(start: minX, end: maxX);
                    chartControlSignal.value = (
                      minX: minX,
                      maxX: maxX,
                      minY: 0.0,
                      maxY: 0.0,
                    );
                  });
                }
              },
              onLegendTapped: (legendTapArgs) =>
                  debugPrint("Legend tapped: ${legendTapArgs.series.name}"),
              series: seriesList,
            ),
          ),
        );
      },
    );
  }

  List<CartesianSeries> _buildChartSeries() {
    final keys = _chartDataContainer.getKeys();
    final colors = _getChartColors();

    final seriesList = <CartesianSeries>[];
    int seriesIndex = 0;

    for (final key in keys) {
      final charts = _chartDataContainer.getCharts(key)!;

      for (final communicatorChart in charts) {
        final color = colors[seriesIndex % colors.length];

        switch (communicatorChart.dataType) {
          case DataType.zeroCrossingRate || DataType.energy:
            {
              seriesList.add(
                StepLineSeries<Point, double>(
                  dataSource: communicatorChart.chart,
                  xValueMapper: (Point point, _) => point.x,
                  yValueMapper: (Point point, _) => point.y,
                  animationDuration: 0,
                ),
              );
            }
          default:
            {
              seriesList.add(
                FastLineSeries<Point, double>(
                  name: key,
                  dataSource: communicatorChart.chart,
                  xValueMapper: (Point point, _) => point.x,
                  yValueMapper: (Point point, _) => point.y,
                  color: color,
                  width: 0.4,
                  animationDuration: 0,
                ),
              );

            }
        }
        seriesIndex++;
      }
    }

    // debugPrint("Total series to render: ${seriesList.length}");

    return seriesList;
  }

  List<Color> _getChartColors() {
    return [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.cyan,
      Colors.pink,
      Colors.amber,
    ];
  }
}
