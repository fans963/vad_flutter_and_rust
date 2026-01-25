import 'package:signals/signals_flutter.dart';
import 'package:flutter/material.dart';

final toolPlateHeightSignal = signal<double>(250.0);

typedef DragUpdateCallback = void Function(double newHeight);
typedef DragStartCallback = double Function();

class GenericDragHandle extends StatefulWidget {
  // 改为 StatefulWidget
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
  State<GenericDragHandle> createState() => _GenericDragHandleState();
}

class _GenericDragHandleState extends State<GenericDragHandle> {
  double _startHeight = 0;
  double _startY = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (details) {
        _startY = details.globalPosition.dy;
        _startHeight = widget.onDragStart();
      },
      onVerticalDragUpdate: (details) {
        final currentY = details.globalPosition.dy;
        final deltaY = currentY - _startY;
        widget.onDragUpdate(_startHeight - deltaY);
      },
      child: Container(
        height: widget.height,
        color: Colors.transparent,
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
