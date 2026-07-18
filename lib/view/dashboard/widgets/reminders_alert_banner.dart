import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/colors/app_color.dart';
import '../../../utils/payment_calculator.dart';
import '../../../view_models/providers/reminder_provider.dart';
import '../../../view_models/providers/settings_provider.dart';
import '../../main/main_view.dart';
import '../../main/screens.dart';

/// Dashboard banner that surfaces due/overdue payment reminders and jumps to
/// the Reminders tab. Renders nothing when there's nothing actionable.
class RemindersAlertBanner extends ConsumerWidget {
  const RemindersAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reminderProvider);
    if (state.actionableCount == 0) return const SizedBox.shrink();

    final overdue = state.overdue.length;
    final today = state.dueToday.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = overdue > 0 ? AppColors.error : AppColors.warning;

    final parts = <String>[
      if (overdue > 0) '$overdue overdue',
      if (today > 0) '$today due today',
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: () => _openReminders(ref),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.spMin, vertical: 12.spMin),
            child: Row(
              children: [
                Icon(TablerIcons.bell_ringing, color: accent, size: 22.spMin),
                SizedBox(width: 12.spMin),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment reminders: ${parts.join('  •  ')}',
                        style: TextStyle(
                          fontSize: 13.spMin,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.spMin),
                      Text(
                        '${PaymentCalculator.formatAmount(state.totalOverdueAmount)} overdue to collect',
                        style: TextStyle(
                          fontSize: 11.spMin,
                          color: isDark ? AppColors.grey300 : AppColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12.spMin,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                Icon(Icons.chevron_right, color: accent, size: 20.spMin),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Switches the main shell to the Reminders tab by finding its index in the
  /// active nav list (accounts for the optional Repairs module shifting it).
  void _openReminders(WidgetRef ref) {
    final showRepairs = ref.read(settingsProvider).showRepairsModule;
    final items = navItemsFor(showRepairs: showRepairs);
    final index = items.indexWhere((i) => i.label == 'Reminders');
    if (index >= 0) {
      ref.read(selectedIndexProvider.notifier).state = index;
    }
  }
}
