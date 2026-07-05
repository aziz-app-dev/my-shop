import 'package:riverpod/legacy.dart';

final navBarProvider = StateNotifierProvider<NavBatNotifier, int>(
  (ref) => NavBatNotifier(),
);

class NavBatNotifier extends StateNotifier<int> {
  NavBatNotifier() : super(0);

  void changeTabIndex(int index) {
    state = index;
  }
}
