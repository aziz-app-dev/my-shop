import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/components/app_bar_widget.dart';
import '../../../res/components/app_icon.dart';
import '../../../view_models/providers/dashboard_provider.dart';

class DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isMobile;
  final VoidCallback? openDrawer;

  const DashboardAppBar({super.key, this.isMobile = false, this.openDrawer});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBarWidget.customAppBar(
      title: 'Dashboard',
      context: context,
      automaticallyImplyLeading: false,
      backIcon: isMobile ? TablerIcons.menu_2 : null,
      actions: [
        // Refresh button
        IconButton(
          onPressed: () => ref.read(dashboardProvider.notifier).refresh(),
          icon: AppIcon(
            size: 18.spMin,
            defaultIcon: TablerIcons.refresh,
            win11IconPath: ImageAssets.win11RotateLeft,
          ),
          tooltip: 'Refresh data',
        ),
      ],
    );
  }
}
