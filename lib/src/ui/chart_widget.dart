import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:vad/src/signals/audio_processor_signal.dart';
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
  double maxXAxis = 10000.0;
  double minYAxis = -0.5;
  double maxYAxis = 0.5;

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
            }
          case ChartEvent_UpdateAllCharts():
            {
              _chartDataContainer.clearAll();
              for (final chart in event.charts) {
                _chartDataContainer.addSeries(chart.key, chart);
              }
            }
          case ChartEvent_RemoveChart():
            {
              _chartDataContainer.removeSeries(event.key);
            }
          case ChartEvent_RemoveAllCharts():
            {
              _chartDataContainer.clearAll();
            }
          case ChartEvent_UpdateMaxIndex():
            {
              maxXAxis = event.maxIndex.toDouble();
            }
          case ChartEvent_UpdateYRange():
            {
              minYAxis = event.minY.toDouble();
              maxYAxis = event.maxY.toDouble();
            }
        }
        setState(() {});
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
                zoomMode: ZoomMode.xy,
                enableDoubleTapZooming: true,
                enableDirectionalZooming: true,
                selectionRectColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.3),
                selectionRectBorderColor: Theme.of(context).colorScheme.primary,
                selectionRectBorderWidth: 1,
                enableSelectionZooming: true,
                enablePinching: true,
                enablePanning: true,
                enableMouseWheelZooming: true,
                maximumZoomLevel: 512.0 / maxXAxis,
              ),
              primaryXAxis: NumericAxis(
                minimum: 0.0,
                maximum: maxXAxis,
                enableAutoIntervalOnZooming: true,
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
              onActualRangeChanged: (ActualRangeChangedArgs rangeChangedArgs) {
                if (rangeChangedArgs.axisName == 'primaryXAxis') {
                  double minX = (rangeChangedArgs.visibleMin as num).toDouble();
                  double maxX = (rangeChangedArgs.visibleMax as num).toDouble();

                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final engine = await audioProcessorEngine.engine();
                    await engine.setIndexRange(start: minX, end: maxX);
                  });
                }
              },
              onLegendTapped: (legendTapArgs) => {
                audioProcessorEngine.engine().then((engine) async {
                  String? seriesName = legendTapArgs.series.name;
                  if (seriesName != null) {
                    engine.setSelectedAudio(chartName: seriesName);
                    engine.reserveVisible(chartName: seriesName);
                  }
                }),
              },
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
                  name: '$key ${communicatorChart.dataType.name}',
                  dataSource: communicatorChart.chart,
                  xValueMapper: (Point point, _) => point.x,
                  yValueMapper: (Point point, _) => point.y,
                  animationDuration: 0,
                  width: 0.4,
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
