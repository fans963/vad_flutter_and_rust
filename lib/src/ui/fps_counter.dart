import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FpsCounter extends StatefulWidget {
  const FpsCounter({super.key});

  @override
  State<FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends State<FpsCounter>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _fps = 0;
  int _frameCount = 0;
  Duration _lastUpdate = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    _frameCount++;
    if (elapsed - _lastUpdate >= const Duration(milliseconds: 500)) {
      setState(() {
        _fps = _frameCount / (elapsed - _lastUpdate).inMilliseconds * 1000;
        _frameCount = 0;
        _lastUpdate = elapsed;
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${_fps.toStringAsFixed(1)} FPS',
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
