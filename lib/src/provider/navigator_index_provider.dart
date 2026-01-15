import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';

class NavigatorIndexProvider extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void setIndex(int index) {
    state = index;
  }
}

final navigatorIndexProvider = NotifierProvider<NavigatorIndexProvider, int>(
  () => NavigatorIndexProvider(),
);
