// 1. 定义回调函数类型
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

typedef DragUpdateCallback = void Function(double newHeight);
typedef DragStartCallback = double Function();

class GenericDragHandle extends ConsumerStatefulWidget {
  final DragUpdateCallback onDragUpdate;
  final DragStartCallback onDragStart;
  final double height;

  const GenericDragHandle({
    super.key,
    required this.onDragUpdate,
    required this.onDragStart,
    this.height = 20,
  });

  @override
  ConsumerState<GenericDragHandle> createState() => _GenericDragHandleState();
}

class _GenericDragHandleState extends ConsumerState<GenericDragHandle> {
  double _startHeight = 0;
  double _startY = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        height: widget.height,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
      onVerticalDragStart: (details) {
        _startY = details.globalPosition.dy;
        _startHeight = widget.onDragStart();
      },
      onVerticalDragUpdate: (details) {
        final currentY = details.globalPosition.dy;
        final deltaY = currentY - _startY;
        widget.onDragUpdate(_startHeight - deltaY);
      },
    );
  }
}

class ToolPlateHeightNotifier extends StateNotifier<double> {
  ToolPlateHeightNotifier(super.initialHeight);

  void updateHeight(double newHeight) {
    state = newHeight;
  }
}

final toolPlateHeightProvider =
    StateNotifierProvider<ToolPlateHeightNotifier, double>(
      (ref) => ToolPlateHeightNotifier(250.0),
    );
