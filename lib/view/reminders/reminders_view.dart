import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../models/bills_model.dart';
import '../../res/colors/app_color.dart';
import '../../utils/app_sizes.dart';
import '../../utils/payment_calculator.dart';
import '../../view_models/providers/reminder_provider.dart';
import '../../view_models/states/reminder_state.dart';
import '../main/main_view.dart';

/// Payment reminders center: shows every pending bill with a due date, grouped
/// into Overdue / Due today / Upcoming, with quick collect + snooze actions.
class RemindersView extends ConsumerStatefulWidget {
  final VoidCallback? openDrawer;

  const RemindersView({super.key, this.openDrawer});

  @override
  ConsumerState<RemindersView> createState() => _RemindersViewState();
}

class _RemindersViewState extends ConsumerState<RemindersView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderProvider.notifier).loadReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final horizontal = AppSizes.isMobile(context) ? 12.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        leading: AppSizes.isMobile(context)
            ? IconButton(
                icon: Icon(Icons.menu, size: 22.spMin),
                onPressed: openAppDrawer,
              )
            : null,
        title: Text('Payment Reminders'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(TablerIcons.refresh, size: 20.spMin),
            onPressed: () => ref.read(reminderProvider.notifier).loadReminders(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(reminderProvider.notifier).loadReminders(),
              child: state.reminders.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontal,
                        vertical: 16.spMin,
                      ),
                      children: [
                        _buildSummaryStrip(state, isDark),
                        SizedBox(height: 16.spMin),
                        _buildSection(
                          title: 'Overdue',
                          icon: TablerIcons.alert_triangle,
                          color: AppColors.error,
                          bills: state.overdue,
                          isDark: isDark,
                        ),
                        _buildSection(
                          title: 'Due Today',
                          icon: TablerIcons.clock_hour_4,
                          color: AppColors.warning,
                          bills: state.dueToday,
                          isDark: isDark,
                        ),
                        _buildSection(
                          title: 'Upcoming',
                          icon: TablerIcons.calendar_event,
                          color: AppColors.info,
                          bills: state.upcoming,
                          isDark: isDark,
                        ),
                        SizedBox(height: 24.spMin),
                      ],
                    ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    // Keep it scrollable so RefreshIndicator's pull-to-refresh still works,
    // while centering the message vertically and horizontally in the viewport.
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 32.spMin,
                  vertical: 24.spMin,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      TablerIcons.bell_check,
                      size: 64.spMin,
                      color: AppColors.grey400,
                    ),
                    SizedBox(height: 16.spMin),
                    Text(
                      'No payment reminders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.spMin,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8.spMin),
                    Text(
                      'Set a due date on a pending bill and it will appear here.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 12.spMin, color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryStrip(ReminderState state, bool isDark) {
    final cardColor = isDark ? AppColors.dCardColor : AppColors.lCardColor;
    Widget tile(String label, String value, Color color, IconData icon) {
      return Expanded(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.spMin),
          padding: EdgeInsets.all(12.spMin),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18.spMin),
              SizedBox(height: 8.spMin),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16.spMin,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              SizedBox(height: 2.spMin),
              Text(
                label,
                style: TextStyle(fontSize: 10.spMin, color: AppColors.grey500),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile('Needs action', '${state.actionableCount}', AppColors.error,
            TablerIcons.urgent),
        tile('Overdue amount',
            PaymentCalculator.formatAmount(state.totalOverdueAmount),
            AppColors.warning, TablerIcons.cash_banknote),
        tile('Total pending',
            PaymentCalculator.formatAmount(state.totalReminderAmount),
            AppColors.info, TablerIcons.receipt),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Bill> bills,
    required bool isDark,
  }) {
    if (bills.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.spMin),
        Row(
          children: [
            Icon(icon, color: color, size: 18.spMin),
            SizedBox(width: 8.spMin),
            Text(
              '$title (${bills.length})',
              style: TextStyle(
                fontSize: 14.spMin,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.spMin),
        ...bills.map((b) => _buildReminderCard(b, color, isDark)),
        SizedBox(height: 8.spMin),
      ],
    );
  }

  Widget _buildReminderCard(Bill bill, Color accent, bool isDark) {
    final cardColor = isDark ? AppColors.dCardColor : AppColors.lCardColor;
    final days = bill.daysUntilDue ?? 0;
    final dueLabel = DateFormat('dd MMM yyyy, hh:mm a').format(bill.dueDate!);
    String relative;
    if (days < 0) {
      relative = '${-days} day${days == -1 ? '' : 's'} overdue';
    } else if (days == 0) {
      relative = 'Due today';
    } else {
      relative = 'In $days day${days == 1 ? '' : 's'}';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.spMin),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(left: BorderSide(color: accent, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(12.spMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.customerName ?? 'Walk-in customer',
                        style: TextStyle(
                          fontSize: 14.spMin,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.spMin),
                      Text(
                        'Bill #${bill.id}',
                        style: TextStyle(
                          fontSize: 10.spMin,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      PaymentCalculator.formatAmount(bill.pendingAmount),
                      style: TextStyle(
                        fontSize: 15.spMin,
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    Text(
                      'pending',
                      style: TextStyle(
                        fontSize: 9.spMin,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.spMin),
            Row(
              children: [
                Icon(TablerIcons.calendar_due,
                    size: 14.spMin, color: accent),
                SizedBox(width: 6.spMin),
                Text(
                  dueLabel,
                  style: TextStyle(
                    fontSize: 11.spMin,
                    color: isDark ? AppColors.grey300 : AppColors.grey700,
                  ),
                ),
                SizedBox(width: 8.spMin),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8.spMin, vertical: 2.spMin),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    relative,
                    style: TextStyle(
                      fontSize: 10.spMin,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.spMin),
            Wrap(
              spacing: 8.spMin,
              runSpacing: 4.spMin,
              children: [
                _actionButton(
                  label: 'Mark paid',
                  icon: TablerIcons.check,
                  color: AppColors.success,
                  onTap: () => _confirmMarkPaid(bill),
                ),
                _snoozeButton(bill),
                _actionButton(
                  label: 'Remove',
                  icon: TablerIcons.bell_off,
                  color: AppColors.grey600,
                  onTap: () =>
                      ref.read(reminderProvider.notifier).clearReminder(bill),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 14.spMin, color: color),
      label: Text(
        label,
        style: TextStyle(fontSize: 11.spMin, color: color),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: EdgeInsets.symmetric(horizontal: 10.spMin, vertical: 4.spMin),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _snoozeButton(Bill bill) {
    return PopupMenuButton<int>(
      tooltip: 'Snooze',
      onSelected: (days) =>
          ref.read(reminderProvider.notifier).snooze(bill, days: days),
      itemBuilder: (context) => [
        PopupMenuItem(value: 1, child: Text('Snooze 1 day')),
        PopupMenuItem(value: 3, child: Text('Snooze 3 days')),
        PopupMenuItem(value: 7, child: Text('Snooze 1 week')),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.spMin, vertical: 5.spMin),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: AppColors.info.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.clock_pause, size: 14.spMin, color: AppColors.info),
            SizedBox(width: 6.spMin),
            Text('Snooze',
                style: TextStyle(fontSize: 11.spMin, color: AppColors.info)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmMarkPaid(Bill bill) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as paid?'),
        content: Text(
          'Record ${PaymentCalculator.formatAmount(bill.pendingAmount)} from '
          '${bill.customerName ?? 'this customer'} as collected? This closes '
          'the bill and removes the reminder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Mark paid'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(reminderProvider.notifier).markPaid(bill);
    }
  }
}
