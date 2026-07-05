import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../utils/app_sizes.dart';
import '../../../view_models/states/repair_state.dart';

/// Status summary cards for the Repairs page, styled to match the
/// Expenses / Dashboard summary cards.
class RepairSummaryCards extends StatelessWidget {
  final RepairState state;

  const RepairSummaryCards({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = <_SummaryCardData>[
      _SummaryCardData(
        icon: TablerIcons.tool,
        win11Icon: ImageAssets.win11Service,
        title: 'Total',
        value: '${state.totalCount}',
        color: AppColors.info,
      ),
      _SummaryCardData(
        icon: TablerIcons.progress,
        win11Icon: ImageAssets.win11Pending,
        title: 'In Repair',
        value: '${state.pendingCount}',
        color: AppColors.warning,
      ),
      _SummaryCardData(
        icon: TablerIcons.circle_check,
        win11Icon: ImageAssets.win11Done,
        title: 'Completed',
        value: '${state.completedCount}',
        color: AppColors.success,
      ),
      _SummaryCardData(
        icon: TablerIcons.cash,
        win11Icon: ImageAssets.win11DollarBag,
        title: 'Balance Due',
        value: 'Rs ${state.totalPendingBalance.toStringAsFixed(0)}',
        color: AppColors.primary,
      ),
    ];

    final twoColumn =
        AppSizes.isTablet(context) || AppSizes.isDesktop(context);

    if (twoColumn) {
      // All four in one row on tablet / desktop.
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i != 0) SizedBox(width: 10.spMin),
            Expanded(child: _card(isDark, cards[i])),
          ],
        ],
      );
    }

    // Mobile: 2 x 2 grid.
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _card(isDark, cards[0])),
            SizedBox(width: 10.spMin),
            Expanded(child: _card(isDark, cards[1])),
          ],
        ),
        SizedBox(height: 10.spMin),
        Row(
          children: [
            Expanded(child: _card(isDark, cards[2])),
            SizedBox(width: 10.spMin),
            Expanded(child: _card(isDark, cards[3])),
          ],
        ),
      ],
    );
  }

  Widget _card(bool isDark, _SummaryCardData data) {
    return Container(
      padding: EdgeInsets.all(AppSizes.tFVerPadding.spMin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.spMin),
        border: Border.all(color: data.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.spMin),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.spMin),
            ),
            child: AppIcon(
              win11IconPath: data.win11Icon,
              defaultIcon: data.icon,
              color: data.color,
              size: 22.spMin,
            ),
          ),
          SizedBox(width: 12.spMin),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                smText(text: data.title, color: Colors.grey),
                SizedBox(height: 2.spMin),
                mdTextBold(text: data.value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardData {
  final IconData icon;
  final String win11Icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCardData({
    required this.icon,
    required this.win11Icon,
    required this.title,
    required this.value,
    required this.color,
  });
}
