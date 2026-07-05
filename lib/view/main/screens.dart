import 'package:desktopapp/models/navigation_models.dart';
import 'package:desktopapp/view/dashboard/dashborad_view.dart';
import 'package:desktopapp/view/home/home_view.dart';
import 'package:desktopapp/view/profile/profile_view.dart';
import 'package:desktopapp/view/sales/multi_cart_sale_view.dart';
import 'package:desktopapp/view/settings/settings_view.dart';
import 'package:desktopapp/view_models/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../res/assets/image_assets.dart';
import '../bills/bills_view.dart';
import '../customers/customer_list_view.dart';
import '../expances/expanses_view.dart';
import '../repairs/repair_view.dart';
import '../sales/sale_view.dart';

//! Navigation Items
const List<NavigationItem> mobileNavItems = [
  NavigationItem(
    icon: TablerIcons.home,
    activeIcon: TablerIcons.home,
    activeWind11Icon: ImageAssets.win11Home,
    label: 'Home',
  ),
  NavigationItem(
    icon: TablerIcons.shopping_bag,
    activeIcon: TablerIcons.shopping_bag,
    activeWind11Icon: ImageAssets.win11Checkout,
    label: 'Sales',
  ),
  NavigationItem(
    icon: TablerIcons.receipt,
    activeIcon: TablerIcons.receipt,
    label: 'Receipts',
    activeWind11Icon: ImageAssets.win11Bill,
  ),
  NavigationItem(
    icon: TablerIcons.users,
    activeIcon: TablerIcons.users,
    label: 'Customers',
    activeWind11Icon: ImageAssets.win11People,
  ),
  NavigationItem(
    icon: Icons.person_4_outlined,
    activeIcon: Icons.person_4_outlined,
    label: 'Profile',
    activeWind11Icon: ImageAssets.win11Administrator,
  ),
];

//! Navigation Items
const List<NavigationItem> desktopNavItems = [
  NavigationItem(
    icon: TablerIcons.home,
    activeIcon: TablerIcons.home,
    label: 'Home',
    activeWind11Icon: ImageAssets.win11Home,
  ),
  NavigationItem(
    icon: TablerIcons.shopping_bag,
    activeIcon: TablerIcons.shopping_bag,
    label: 'Sales',
    activeWind11Icon: ImageAssets.win11Checkout,
  ),
  NavigationItem(
    icon: TablerIcons.receipt,
    activeIcon: TablerIcons.receipt,
    label: 'Receipts',
    activeWind11Icon: ImageAssets.win11Bill,
  ),
  NavigationItem(
    icon: TablerIcons.users,
    activeIcon: TablerIcons.users,
    label: 'Customers',
    activeWind11Icon: ImageAssets.win11People,
  ),

  NavigationItem(
    icon: Icons.person_4_outlined,
    activeIcon: Icons.person_4_outlined,
    label: 'Profile',
    activeWind11Icon: ImageAssets.win11Administrator,
  ),
  NavigationItem(
    icon: TablerIcons.report_money,
    activeIcon: TablerIcons.report_money,
    label: 'Expenses',
    activeWind11Icon: ImageAssets.win11Invoice,
  ),
  NavigationItem(
    icon: TablerIcons.chart_pie,
    activeIcon: TablerIcons.chart_pie,
    label: 'Dashboard',
    activeWind11Icon: ImageAssets.win11Accounting,
  ),
  NavigationItem(
    icon: TablerIcons.settings,
    activeIcon: TablerIcons.settings,
    label: 'Settings',
    activeWind11Icon: ImageAssets.win11Settings,
  ),
];

// Repairs nav item — inserted conditionally based on settings.
const NavigationItem _repairsNavItem = NavigationItem(
  icon: TablerIcons.tool,
  activeIcon: TablerIcons.tool,
  label: 'Repairs',
  activeWind11Icon: ImageAssets.win11Service,
);

/// Builds the desktop/tablet nav items, optionally including the Repairs module.
/// Repairs is inserted right after Customers so it sits next to other
/// client-facing features. The returned list MUST stay index-aligned with
/// [pages]; both are built from the same [showRepairs] flag.
List<NavigationItem> navItemsFor({required bool showRepairs}) {
  final items = List<NavigationItem>.from(desktopNavItems);
  if (showRepairs) {
    final insertAt = items.indexWhere((i) => i.label == 'Customers') + 1;
    items.insert(insertAt, _repairsNavItem);
  }
  return items;
}

// Sales screen selector based on settings
class SalesScreenSelector extends ConsumerWidget {
  const SalesScreenSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useMultiCart = ref.watch(
      settingsProvider.select((s) => s.useMultiCart),
    );

    return useMultiCart ? const MultiCartSalesScreen() : const SalesScreen();
  }
}

/// Builds the page list. MUST stay index-aligned with [navItemsFor]; the
/// Repairs page is inserted at the same position (after Customers) using the
/// same [showRepairs] flag.
List<Widget> pages(
  GlobalKey<ScaffoldState> scaffoldKey, {
  bool showRepairs = true,
}) {
  final list = <Widget>[
    HomePage(openDrawer: () => scaffoldKey.currentState?.openDrawer()),
    const SalesScreenSelector(), // Dynamically shows single or multi-cart based on settings
    BillsScreen(),
    CustomerListScreen(),
    ProfileView(openDrawer: () => scaffoldKey.currentState?.openDrawer()),
    ExpensesView(openDrawer: () => scaffoldKey.currentState?.openDrawer()),
    DashboradView(openDrawer: () => scaffoldKey.currentState?.openDrawer()),
    SettingsPage(openDrawer: () => scaffoldKey.currentState?.openDrawer()),
  ];
  if (showRepairs) {
    // CustomerListScreen is at index 3 → insert Repairs at index 4.
    list.insert(
      4,
      RepairView(openDrawer: () => scaffoldKey.currentState?.openDrawer()),
    );
  }
  return list;
}
