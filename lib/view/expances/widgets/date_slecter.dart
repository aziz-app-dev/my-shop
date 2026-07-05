import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../utils/app_sizes.dart';
import '../../../view_models/providers/expense_provider.dart';

Widget buildMonthSelector(WidgetRef ref, ExpenseState state) {
  final monthName = DateFormat('MMM yyyy').format(state.selectedMonth);
  final isDark = Theme.of(ref.context).brightness == Brightness.dark;

  return InkWell(
    onTap: () => _showMonthPicker(ref, state),
    borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg.r),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.spMin, vertical: 6.spMin),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.primaryLight1,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            win11IconPath: ImageAssets.win11CalendarPlus,
            defaultIcon: TablerIcons.calendar,
            size: 16.spMin,
            color: AppColors.primary,
          ),
          SizedBox(width: 6.w),
          Text(
            monthName,
            style: TextStyle(
              fontSize: 13.spMin,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 4.spMin),
          Icon(
            TablerIcons.chevron_down,
            size: 14.spMin,
            color: AppColors.primary,
          ),
        ],
      ),
    ),
  );
}

void _showMonthPicker(WidgetRef ref, ExpenseState state) {
  showDialog(
    context: ref.context,
    builder:
        (dialogContext) => _MonthPickerDialog(
          selectedMonth: state.selectedMonth,
          onMonthSelected: (month) {
            ref.read(expenseProvider.notifier).setSelectedMonth(month);
            Navigator.pop(dialogContext);
          },
        ),
  );
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const _MonthPickerDialog({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonthIndex;

  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedMonth.year;
    _selectedMonthIndex = widget.selectedMonth.month - 1;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    return AlertDialog(
      title: Row(
        children: [
          Icon(TablerIcons.calendar_month, color: AppColors.primary),
          SizedBox(width: 8.spMin),
          const Text('Select Month'),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(TablerIcons.chevron_left),
                  onPressed: () => setState(() => _selectedYear--),
                ),
                Text(
                  _selectedYear.toString(),
                  style: TextStyle(
                    fontSize: 18.spMin,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(TablerIcons.chevron_right),
                  onPressed:
                      _selectedYear < now.year
                          ? () => setState(() => _selectedYear++)
                          : null,
                ),
              ],
            ),
            SizedBox(height: 16.spMin),
            // Month grid
            GridView.builder(
              shrinkWrap: true,
              // physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: AppSizes.isMobile(context) ? 3 : 5,
                childAspectRatio: 2,
                crossAxisSpacing: 26.spMin,
                mainAxisSpacing: 26.spMin,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final isSelected =
                    _selectedYear == widget.selectedMonth.year &&
                    index == _selectedMonthIndex;
                final isFuture =
                    _selectedYear == now.year && index > now.month - 1;

                return InkWell(
                  onTap:
                      isFuture
                          ? null
                          : () {
                            setState(() => _selectedMonthIndex = index);
                          },
                  borderRadius: BorderRadius.circular(8.r),
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary
                              : _selectedMonthIndex == index
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : isDark
                              ? AppColors.grey800
                              : AppColors.grey100,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _months[index].substring(0, 3),
                      style: TextStyle(
                        fontSize: 13.spMin,
                        fontWeight:
                            isSelected || _selectedMonthIndex == index
                                ? FontWeight.bold
                                : FontWeight.normal,
                        // color:
                        // isFuture
                        //     ? Colors.grey
                        //     : isSelected
                        //     ? Colors.white
                        //     : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onMonthSelected(
              DateTime(_selectedYear, _selectedMonthIndex + 1, 1),
            );
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
