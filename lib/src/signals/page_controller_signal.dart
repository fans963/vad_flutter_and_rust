import 'package:flutter/material.dart';
import 'package:signals/signals_flutter.dart';

final pageControllerSignal = Signal<PageController>(
  PageController(initialPage: 0),
);

final pageIndexSignal = signal(0);
