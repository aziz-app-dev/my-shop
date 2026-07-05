import 'package:desktopapp/models/navigation_models.dart';
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:desktopapp/view/main/infoCard.dart';
import 'package:desktopapp/view/main/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../res/components/app_icon.dart';
import '../../view_models/providers/profile_provider.dart';
import '../../view_models/providers/settings_provider.dart';

// Riverpod provider for selected index
final selectedIndexProvider = StateProvider<int>((ref) => 0);

class MainScrenn extends ConsumerStatefulWidget {
  const MainScrenn({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MainScrennState();
}

class _MainScrennState extends ConsumerState<MainScrenn> {
  @override
  void initState() {
    super.initState();
    ref.read(profileProvider.notifier).loadUserData();
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
          child: AppIcon(
            defaultIcon: selectedIndex == index ? item.activeIcon : item.icon,
            win11IconPath: item.activeWind11Icon,
            color: selectedIndex == index ? activeIconColor : inactiveIconColor,
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
    final selectedIndex = ref.watch(selectedIndexProvider);
    final showRepairs = ref.watch(
      settingsProvider.select((s) => s.showRepairsModule),
    );
    final navItems = navItemsFor(showRepairs: showRepairs);

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
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
              Expanded(
                child: pageList[safeIndex],
              ), // Pass scaffoldKey
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
            Expanded(
              child: pageList[safeIndex],
            ), // Pass scaffoldKey
          ],
        ),
      );
    } else {
      return Scaffold(
        key: scaffoldKey,
        drawer: buildMobileDrawer(ref), // Always enable the drawer
        body: pageList[safeIndex], // Pass scaffoldKey
        bottomNavigationBar: buildMobileBottomNavBar(ref, navItems),
      );
    }
  }
}
