import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TestChartWidget extends StatefulWidget {
  const TestChartWidget({super.key});

  @override
  State<TestChartWidget> createState() => _TestChartWidgetState();
}

class _TestChartWidgetState extends State<TestChartWidget> {
  late Float64List _xValues;
  late Float64List _yValues;
  late List<int> _indices;
  final int _totalPoints = 100000;

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _generateData() {
    _xValues = Float64List(_totalPoints);
    _yValues = Float64List(_totalPoints);
    _indices = List<int>.generate(_totalPoints, (i) => i);
    for (int i = 0; i < _totalPoints; i++) {
      _xValues[i] = i.toDouble();
      _yValues[i] = sin(i * 0.01) * 100 + cos(i * 0.001) * 50;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(16.0),
      child: RepaintBoundary(
        child: SfCartesianChart(
          // 1. 开启鼠标和手势缩放行为
          zoomPanBehavior: ZoomPanBehavior(
            enablePinching: true, // 开启双指缩放
            enablePanning: true, // 开启平移
            enableMouseWheelZooming: true, // 核心：开启鼠标滚轮缩放
            enableSelectionZooming: true, // 开启鼠标框选缩放
            zoomMode: ZoomMode.xy, // 通常大数据量建议只沿X轴缩放
          ),

          primaryXAxis: const NumericAxis(
            // 2. 启用二分查找裁剪，这是缩放时不卡顿的关键
            // 虽然一次性显示10万点，但在缩放进去后，图表会自动只渲染可见点
            initialVisibleMinimum: 0,
            initialVisibleMaximum: 100000,
            edgeLabelPlacement: EdgeLabelPlacement.shift,
          ),

          primaryYAxis: const NumericAxis(
            // 固定 Y 轴范围，避免缩放 X 轴时 Y 轴不断重新计算范围（极度耗时）
            minimum: -160,
            maximum: 160,
          ),

          series: <CartesianSeries<int, double>>[
            FastLineSeries<int, double>(
              dataSource: _indices,
              xValueMapper: (int index, _) => _xValues[index],
              yValueMapper: (int index, _) => _yValues[index],

              // 3. 性能核心参数
              animationDuration: 0,
              width: 0.4,
              color: Colors.blue,

              // 4. 必须告知数据是有序的
              // 缩放和平移时，引擎会利用这个属性进行二分查找优化
              sortingOrder: SortingOrder.ascending,
              sortFieldValueMapper: (int index, _) => _xValues[index],
            ),
          ],
        ),
      ),
    );
  }
}
