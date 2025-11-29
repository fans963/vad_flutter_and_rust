import 'package:flutter_riverpod/legacy.dart';

class NavigatorIndexProvider extends StateNotifier<int> {
  NavigatorIndexProvider() : super(0);

  void setIndex(int index) {
    state = index;
  }
}

final navigatorIndexProvider =
    StateNotifierProvider<NavigatorIndexProvider, int>(
      (ref) => NavigatorIndexProvider(),
    );
