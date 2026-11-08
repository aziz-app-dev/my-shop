import 'package:desktopapp/models/navigation_models.dart';
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:desktopapp/view/main/infoCard.dart';
import 'package:desktopapp/view/main/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../res/components/app_icon.dart';
import '../../view_models/providers/profile_provider.dart';
import '../../view_models/providers/reminder_provider.dart';
import '../../view_models/providers/settings_provider.dart';
import '../../view_models/services/keyboard/app_keyboard_service.dart';
import '../about/about_view.dart';

// Riverpod provider for selected index
final selectedIndexProvider = StateProvider<int>((ref) => 0);

/// Index of the Home page in the nav/page lists. Used by the mobile system-back
/// handler to return to Home (navigation is index-based, not a route stack).
const int kHomeIndex = 0;

/// Index of the Sales page in the nav/page lists — the home page's scan
/// button jumps here after a successful add-to-cart (see
/// barcode_scan_flow.dart usage in home_view.dart).
const int kSalesIndex = 1;

/// Key on the mobile shell Scaffold that owns the navigation drawer, so any
/// page can open the drawer without the key being threaded through.
final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();

/// Open the app's navigation drawer (mobile). Every page's hamburger uses this.
void openAppDrawer() => rootScaffoldKey.currentState?.openDrawer();

/// Switch the shell back to the Home tab (used by the mobile system-back).
void navigateHome(WidgetRef ref) =>
    ref.read(selectedIndexProvider.notifier).state = kHomeIndex;

class MainScrenn extends ConsumerStatefulWidget {
  const MainScrenn({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainScrennState();
}

class _MainScrennState extends ConsumerState<MainScrenn> {
  /// App-wide navigation scope. Registered for the whole app lifetime so the
  /// F-key navigation works no matter where the focus is (see
  /// [AppKeyboardScope] — window-level dispatch, not focus-dependent).
  /// Page-specific scopes (e.g. Sales' Tab/arrow/Enter product navigation)
  /// register later, so
  /// they win over these bindings while their page is on screen.
  late final AppKeyboardScope _navKeys = AppKeyboardScope(
    'main-nav',
    _handleNavKey,
  );

  @override
  void initState() {
    super.initState();
    ref.read(profileProvider.notifier).loadUserData();
    AppKeyboardScope.register(_navKeys);
  }

  @override
  void dispose() {
    AppKeyboardScope.unregister(_navKeys);
    super.dispose();
  }

  bool _handleNavKey(KeyEvent event) {
    final showRepairs = ref.read(settingsProvider).showRepairsModule;
    final itemCount = navItemsFor(showRepairs: showRepairs).length;

    const fKeys = [
      LogicalKeyboardKey.f1,
      LogicalKeyboardKey.f2,
      LogicalKeyboardKey.f3,
      LogicalKeyboardKey.f4,
      LogicalKeyboardKey.f5,
      LogicalKeyboardKey.f6,
      LogicalKeyboardKey.f7,
      LogicalKeyboardKey.f8,
      LogicalKeyboardKey.f9,
      LogicalKeyboardKey.f10,
    ];
    for (var i = 0; i < fKeys.length && i < itemCount; i++) {
      if (AppKeyboardScope.didPress(event, fKeys[i])) {
        ref.read(selectedIndexProvider.notifier).state = i;
        return true;
      }
    }
    // 11th section only exists when the Repairs module is enabled.
    if (itemCount > 10 &&
        AppKeyboardScope.didPress(event, LogicalKeyboardKey.f12)) {
      ref.read(selectedIndexProvider.notifier).state = 10;
      return true;
    }
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.f11)) {
      _showShortcutsHelp(context);
      return true;
    }
    return false;
  }

  /// Overlays a small red dot on the Reminders nav icon when there is at least
  /// one active payment reminder. No-op for every other nav item.
  Widget _withReminderDot(
    WidgetRef ref,
    NavigationItem item,
    Widget iconWidget,
  ) {
    if (item.label != 'Reminders') return iconWidget;
    final hasReminders = ref.watch(
      reminderProvider.select((s) => s.reminders.isNotEmpty),
    );
    if (!hasReminders) return iconWidget;
    final Color bgColor =
        Theme.of(context).brightness == Brightness.dark
            ? (AppColors.dBottomNavBarColor ?? Colors.black)
            : Colors.white;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -2.spMin,
          top: -2.spMin,
          child: Container(
            width: 9.spMin,
            height: 9.spMin,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
              border: Border.all(color: bgColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Modal listing every shortcut, generated from the live nav item list so it
  /// always matches the enabled modules (e.g. Repairs on/off).
  void _showShortcutsHelp(BuildContext context) {
    final showRepairs = ref.read(
      settingsProvider.select((s) => s.showRepairsModule),
    );
    final navItems = navItemsFor(showRepairs: showRepairs);

    Widget keyChip(String label) => Container(
      width: 34.spMin,
      height: 26.spMin,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.spMin,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    final rows = <Widget>[];
    for (var i = 0; i < navItems.length; i++) {
      rows.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              keyChip(i < 10 ? 'F${i + 1}' : 'F12'),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  navItems[i].label,
                  style: TextStyle(fontSize: 13.spMin),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(
              'Keyboard Shortcuts',
              style: TextStyle(fontSize: 18.spMin),
            ),
            content: SizedBox(
              width: 300.spMin,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...rows,
                    const Divider(),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          keyChip('F11'),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Show this shortcuts help',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Text(
                        'Purchases (Local Purchase Agreements)',
                        style: TextStyle(
                          fontSize: 12.spMin,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...[
                      ('Ctrl + N', 'New purchase agreement'),
                      ('Ctrl + S', 'Save the agreement you are editing'),
                      ('Ctrl + P', 'Print the agreement'),
                    ].map(
                      (e) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 3.h),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                e.$1,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.spMin,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                e.$2,
                                style: TextStyle(fontSize: 12.spMin),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: EdgeInsets.only(top: 8.h),
                      child: Text(
                        'On the Sales screen, Tab (or the arrow keys) walks '
                        'the items and Enter sends the selected one to the '
                        'cart; Esc clears the selection. When a search '
                        'matches exactly one product, pressed Enter sends it '
                        'straight to the cart. Ctrl + Enter completes the '
                        'sale and opens the payment page (on that page, '
                        'Ctrl + Enter saves it too). An empty name on the '
                        'payment page means a walk-in customer.',
                        style: TextStyle(
                          fontSize: 12.spMin,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutView()),
                  );
                },
                child: const Text('Full guide'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget buildDesktopDrawer(WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final showRepairs = ref.watch(
      settingsProvider.select((s) => s.showRepairsModule),
    );
    final navItems = navItemsFor(showRepairs: showRepairs);
    final Color activeIconColor = AppColors.primary;
    final Color inactiveIconColor = Colors.grey[600]!;
    return Container(
      color:
          (Theme.of(context).brightness == Brightness.dark
              ? AppColors.dBottomNavBarColor
              : Colors.white),
      width: 185.spMin,
      child: Column(
        children: [
          infoCard(ref),
          ...navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12.0),
                onTap:
                    () =>
                        ref.read(selectedIndexProvider.notifier).state = index,
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color:
                        selectedIndex == index
                            ? activeIconColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      _withReminderDot(
                        ref,
                        item,
                        AppIcon(
                          defaultIcon:
                              selectedIndex == index
                                  ? item.activeIcon
                                  : item.icon,
                          win11IconPath: item.activeWind11Icon,
                          color:
                              selectedIndex == index
                                  ? activeIconColor
                                  : inactiveIconColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontWeight:
                              selectedIndex == index
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget buildTabletNavItem(int index, NavigationItem item, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final Color activeIconColor = AppColors.primary;
    final Color inactiveIconColor = Colors.grey[600]!;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.spMin),
      child: InkWell(
        borderRadius: BorderRadius.circular(6.r),
        hoverColor: activeIconColor.withValues(alpha: 0.2),
        splashColor: activeIconColor.withValues(alpha: 0.3),

        onTap: () {
          ref.read(selectedIndexProvider.notifier).state = index;
        },
        child: Container(
          padding: EdgeInsets.all(12.spMin),
          decoration: BoxDecoration(
            color:
                selectedIndex == index
                    ? activeIconColor.withValues(alpha: 0.2)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: _withReminderDot(
            ref,
            item,
            AppIcon(
              defaultIcon: selectedIndex == index ? item.activeIcon : item.icon,
              win11IconPath: item.activeWind11Icon,
              color:
                  selectedIndex == index ? activeIconColor : inactiveIconColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMobileDrawer(WidgetRef ref) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final showRepairs = ref.watch(
      settingsProvider.select((s) => s.showRepairsModule),
    );
    final navItems = navItemsFor(showRepairs: showRepairs);
    final Color activeIconColor = AppColors.primary;
    final Color inactiveIconColor = Colors.grey[600]!;

    return Drawer(
      child: FocusScope(
        child: Builder(
          builder: (BuildContext drawerContext) {
            return Column(
              children: [
                infoCard(ref),
                ...navItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 2.h,
                    ),
                    child: InkWell(
                      focusNode: FocusNode(
                        // Skip traversal to avoid unnecessary focus events
                        skipTraversal: true,
                        // Ensure focus is not retained after disposal
                        // onDispose: () {},
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        // Update state and close drawer in a post-frame callback
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref.read(selectedIndexProvider.notifier).state =
                              index;
                          Navigator.pop(drawerContext);
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.h),
                        decoration: BoxDecoration(
                          color:
                              selectedIndex == index
                                  ? activeIconColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          children: [
                            _withReminderDot(
                              ref,
                              item,
                              AppIcon(
                                defaultIcon:
                                    selectedIndex == index
                                        ? item.activeIcon
                                        : item.icon,
                                win11IconPath: item.activeWind11Icon,
                                color:
                                    selectedIndex == index
                                        ? activeIconColor
                                        : inactiveIconColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(item.label),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget buildMobileBottomNavBar(WidgetRef ref) {
  //   final selectedIndex = ref.watch(selectedIndexProvider);
  //   final Color activeIconColor = AppColors.primary;
  //   final Color inactiveIconColor = Colors.grey[600]!;

  //   return NavigationBar(
  //     backgroundColor:
  //         (Theme.of(context).brightness == Brightness.dark
  //             ? AppColors.dBottomNavBarColor
  //             : Colors.white),
  //     indicatorColor: Colors.transparent,
  //     selectedIndex: selectedIndex,
  //     overlayColor: WidgetStatePropertyAll(Colors.transparent),

  //     labelTextStyle: WidgetStatePropertyAll(
  //       TextStyle(fontSize: 12.spMin, fontWeight: FontWeight.bold),
  //     ),
  //     onDestinationSelected:
  //         (index) => ref.read(selectedIndexProvider.notifier).state = index,
  //     destinations:
  //         mobileNavItems
  //             .map(
  //               (item) => NavigationDestination(
  //                 icon: Icon(item.icon, color: inactiveIconColor),
  //                 selectedIcon: Container(
  //                   decoration: BoxDecoration(
  //                     color: activeIconColor.withValues(alpha: 0.2),
  //                     borderRadius: BorderRadius.circular(12.0),
  //                   ),
  //                   child: Padding(
  //                     padding: EdgeInsets.all(8.h),
  //                     child: Icon(
  //                       item.activeIcon,
  //                       color: activeIconColor,
  //                       size: 22.spMin,
  //                     ),
  //                   ),
  //                 ),

  //                 label: item.label,
  //               ),
  //             )
  //             .toList(),
  //   );
  // }

  Widget buildMobileBottomNavBar(WidgetRef ref, List<NavigationItem> navItems) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final Color activeIconColor = AppColors.primary;
    final Color inactiveIconColor = Colors.grey[600]!;

    // The bottom bar shows a fixed 5-tab subset. Map each tab to its position
    // in the full nav/page list (by label) so selection stays correct even
    // when optional modules like Repairs shift the indices.
    int pageIndexFor(NavigationItem item) {
      final i = navItems.indexWhere((n) => n.label == item.label);
      return i >= 0 ? i : 0;
    }

    final selectedTab = mobileNavItems.indexWhere(
      (item) => pageIndexFor(item) == selectedIndex,
    );

    return NavigationBar(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.dBottomNavBarColor
              : Colors.white,

      indicatorColor: Colors.transparent,
      selectedIndex: selectedTab >= 0 ? selectedTab : 0,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),

      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 12.spMin, fontWeight: FontWeight.bold, height: 0.8),
      ),

      onDestinationSelected:
          (tab) =>
              ref.read(selectedIndexProvider.notifier).state = pageIndexFor(
                mobileNavItems[tab],
              ),

      destinations:
          mobileNavItems.map((item) {
            return NavigationDestination(
              label: item.label,

              // 👇 SAME size for unselected
              icon: _buildNavIcon(
                icon: item.icon,
                win11IconPath: item.activeWind11Icon,

                color: inactiveIconColor,
                isActive: false,
                activeColor: activeIconColor,
              ),

              // 👇 SAME size for selected
              selectedIcon: _buildNavIcon(
                icon: item.activeIcon,
                win11IconPath: item.activeWind11Icon,
                color: activeIconColor,
                isActive: true,
                activeColor: activeIconColor,
              ),
            );
          }).toList(),
    );
  }

  /// 🔒 Fixed-size icon widget
  Widget _buildNavIcon({
    required IconData icon,
    required String win11IconPath,
    required Color color,
    required bool isActive,
    required Color activeColor,
  }) {
    return SizedBox(
      width: 48.spMin,
      height: 48.spMin,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration:
              isActive
                  ? BoxDecoration(
                    color: activeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  )
                  : null,
          child: AppIcon(defaultIcon: icon, win11IconPath: win11IconPath),
          //  Icon(
          //   icon,
          //   color: color,
          //   size: 22, // 🔒 FIXED SIZE
          // ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildShell(context);
  }

  Widget _buildShell(BuildContext context) {
    final selectedIndex = ref.watch(selectedIndexProvider);
    final showRepairs = ref.watch(
      settingsProvider.select((s) => s.showRepairsModule),
    );
    final navItems = navItemsFor(showRepairs: showRepairs);

    // Use the global root key so any page's hamburger can open this drawer.
    final scaffoldKey = rootScaffoldKey;
    final pageList = pages(scaffoldKey, showRepairs: showRepairs);
    // Guard against an out-of-range index when the Repairs module is toggled
    // off while it (or a later page) was selected.
    final safeIndex = selectedIndex.clamp(0, pageList.length - 1);

    if (AppSizes.isTablet(context)) {
      return SafeArea(
        child: Scaffold(
          body: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color:
                    (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dBottomNavBarColor
                        : Colors.white),
                height: MediaQuery.sizeOf(context).height,
                width: 80.spMin,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),
                      tabIcon(ref),
                      SizedBox(height: 20.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Divider(),
                      ),
                      ...navItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return buildTabletNavItem(index, item, ref);
                      }),
                    ],
                  ),
                ),
              ),
              VerticalDivider(),
              Expanded(child: pageList[safeIndex]), // Pass scaffoldKey
            ],
          ),
        ),
      );
    } else if (AppSizes.isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            buildDesktopDrawer(ref),
            VerticalDivider(),
            Expanded(child: pageList[safeIndex]), // Pass scaffoldKey
          ],
        ),
      );
    } else {
      // Mobile: no bottom nav. The hamburger (on Home) opens the full drawer;
      // every sub-page shows a back arrow → Home. System/gesture back also
      // returns to Home first, only exiting the app from Home.
      return PopScope(
        canPop: safeIndex == kHomeIndex,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) navigateHome(ref);
        },
        child: Scaffold(
          key: scaffoldKey,
          drawer: buildMobileDrawer(ref), // Always enable the drawer
          body: pageList[safeIndex],
        ),
      );
    }
  }
}
