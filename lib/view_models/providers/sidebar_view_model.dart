import 'package:desktopapp/routes/routes_name.dart';
import 'package:desktopapp/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/legacy.dart';

import '../states/side_bar_State.dart';

class Sidebarprovider extends StateNotifier<SidebarState> {
  Sidebarprovider()
    : super(SidebarState(activeItem: RouteName.dashBordScreen, hoverItem: ''));

  void changeActiveItem(String route) {
    state = state.copyWith(activeItem: route);
  }

  void changeHoverItem(String route) {
    state = state.copyWith(hoverItem: route);
  }

  bool isActive(String route) => state.activeItem == route;

  bool isHovering(String route) => state.hoverItem == route;

  void menuOnTap(BuildContext context, String route) {
    if (!isActive(route)) {
      changeActiveItem(route);

      if (Utils.isMobileScreen(context)) {
        Navigator.pop(context); // Close drawer on mobile
      }
      Navigator.pushNamed(context, route);
    }
  }
}

final sidebarProvider = StateNotifierProvider<Sidebarprovider, SidebarState>((
  ref,
) {
  return Sidebarprovider();
});
