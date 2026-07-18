import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/components/app_bar_widget.dart';
import '../../../res/components/app_flushbar.dart';
import '../../../res/components/app_icon.dart';
import '../../../view_models/providers/dashboard_provider.dart';
import '../../main/main_view.dart';
import 'financial_report_service.dart';

class DashboardAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isMobile;
  final VoidCallback? openDrawer;

  const DashboardAppBar({super.key, this.isMobile = false, this.openDrawer});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Builds the period financial report PDF from the current dashboard data
  /// and opens it. Runs on the currently selected month/year view.
  Future<void> _generateReport(BuildContext context, WidgetRef ref) async {
    final state = ref.read(dashboardProvider);
    AppFlushbar.success(context, message: 'Generating financial report…');
    try {
      await FinancialReportService.buildSaveOpen(ref: ref, state: state);
      if (!context.mounted) return;
      AppFlushbar.success(context, message: 'Financial report generated');
    } catch (e) {
      if (!context.mounted) return;
      AppFlushbar.error(context, message: 'Failed to generate report: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBarWidget.customAppBar(
      title: 'Dashboard',
      context: context,
      automaticallyImplyLeading: isMobile,
      backIcon: isMobile ? Icons.menu : null,
      winBackIcon: isMobile ? ImageAssets.win11Menu : null,
      leadingOnTap: isMobile ? openAppDrawer : null,
      actions: [
        // Generate financial report (PDF)
        IconButton(
          onPressed: () => _generateReport(context, ref),
          icon: AppIcon(
            size: 18.spMin,
            defaultIcon: TablerIcons.file_download,
            win11IconPath: ImageAssets.win11Invoice,
          ),
          tooltip: 'Generate financial report (PDF)',
        ),
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
