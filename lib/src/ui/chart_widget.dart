import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:vad/src/provider/audio_process_providr.dart';
import 'package:vad/src/provider/chart_control_provider.dart';
import 'package:vad/src/provider/chart_paramater_provider.dart';
import 'package:vad/src/rust/api/events/communicator_events.dart';
import 'package:vad/src/rust/api/types/chart.dart';
import 'package:vad/src/rust/api/types/events.dart';

class ChartWidget extends ConsumerStatefulWidget {
  const ChartWidget({super.key});

  @override
  ConsumerState<ChartWidget> createState() => _ChartWidgetState();
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

class _ChartWidgetState extends ConsumerState<ChartWidget> {
  StreamSubscription<ChartEvent>? _chartEventSubscription;
  final _containerKey = GlobalKey();
  double? _lastWidth;
  late final _ChartDataContainer _chartDataContainer = _ChartDataContainer();

  @override
  void initState() {
    super.initState();
    _chartEventSubscription = createChartEventStream().listen(
      (event) {
        switch (event) {
          case ChartEvent_AddChart():
            {
              _chartDataContainer.addSeries(event.chart.key, event.chart);
              debugPrint(
                "Received ChartEvent_AddChart: ${event.chart.key}, points: ${event.chart.chart.length}",
              );
              setState(() {});
            }
          case ChartEvent_UpdateAllCharts():
            {
              _chartDataContainer.clearAll();
              for (final chart in event.charts) {
                _chartDataContainer.addSeries(chart.key, chart);
              }
              debugPrint(
                "Received ChartEvent_UpdateAllCharts: total charts: ${event.charts.length}",
              );
              setState(() {});
            }
          case ChartEvent_RemoveChart():
            {
              _chartDataContainer.removeSeries(event.key);
              debugPrint("Removed chart: ${event.key}");
              setState(() {});
            }
          case ChartEvent_RemoveAllCharts():
            {
              _chartDataContainer.clearAll();
              debugPrint("Removed all charts");
              setState(() {});
            }
        }
      },
      onError: (error) => debugPrint('Chart event stream error: $error'),
      cancelOnError: false,
    );

    _listenToSizeChanges();
  }

  void _listenToSizeChanges() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateDownsamplePointsNum();
      _listenToSizeChanges();
    });
  }

  void _updateDownsamplePointsNum() {
    final size = _containerKey.currentContext?.size;
    if (size != null && size.width != _lastWidth) {
      _lastWidth = size.width;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(audioProcessorProvider)
            .value
            ?.setDownSamplePointsNum(pointsNum: BigInt.from(size.width * 2));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartControl = ref.watch(chartControlProvider);
    final chartParameters = ref.watch(chartParameterProvider);

    ref.listen(chartControlProvider, (previous, next) {
      next.whenData((control) {
        ref
            .read(audioProcessorProvider)
            .value
            ?.setIndexRange(start: control.minX, end: control.maxX);
        debugPrint(
          "Chart control updated: minX=${control.minX}, maxX=${control.maxX}",
        );
      });
    });

    final seriesList = _buildChartSeries();

    return Container(
      key: _containerKey,
      height: 500,
      padding: const EdgeInsets.all(10.0),
      child: RepaintBoundary(
        child: SfCartesianChart(
          zoomPanBehavior: ZoomPanBehavior(
            enablePinching: true,
            enablePanning: true,
            enableMouseWheelZooming: true,
            enableSelectionZooming: true,
            zoomMode: ZoomMode.x,
          ),
          primaryXAxis: NumericAxis(
            name: 'primaryXAxis',
            minimum: 0,
            maximum: 10000,
          ),
          primaryYAxis: const NumericAxis(
            name: 'primaryYAxis',
            minimum: -0.5,
            maximum: 0.5,
          ),
          onActualRangeChanged: (ActualRangeChangedArgs rangeChangedArgs) {
            if (rangeChangedArgs.axisName == 'primaryXAxis') {
              final minX = (rangeChangedArgs.visibleMin as num).toDouble();
              final maxX = (rangeChangedArgs.visibleMax as num).toDouble();

              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(chartControlProvider.notifier).setControlParameter((
                  minX: minX,
                  maxX: maxX,
                  minY: 0.0,
                  maxY: 0.0,
                ));
              });
            }
          },
          series: seriesList,
        ),
      ),
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

        seriesList.add(
          FastLineSeries<Point, double>(
            name: key,
            dataSource: communicatorChart.chart,
            xValueMapper: (Point point, _) => point.x,
            yValueMapper: (Point point, _) => point.y,
            color: color,
            width: 0.4,
            animationDuration: 0,
            sortingOrder: SortingOrder.ascending,
            sortFieldValueMapper: (Point point, _) => point.x,
          ),
        );

        seriesIndex++;
      }
    }

    debugPrint("Total series to render: ${seriesList.length}");

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
