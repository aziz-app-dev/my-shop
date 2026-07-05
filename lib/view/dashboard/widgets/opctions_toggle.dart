import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../view_models/providers/dashboard_provider.dart';

Widget toggleRow(WidgetRef ref) {
  final dashboardState = ref.watch(dashboardProvider);
  final isYearly = dashboardState.isYearlyView;
  final monthName = DateFormat(
    'MMMM yyyy',
  ).format(dashboardState.selectedMonth);
  final yearName = dashboardState.selectedMonth.year.toString();

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // Monthly/Yearly Toggle
      buildViewToggle(ref, isYearly),
      // Date selector chip (Month or Year based on view)
      InkWell(
        onTap:
            isYearly
                ? () => _showYearPicker(ref, dashboardState.selectedMonth)
                : () => _showMonthPicker(ref, dashboardState.selectedMonth),
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.spMin,
            vertical: 6.spMin,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ref.context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                size: 16.spMin,
                defaultIcon: TablerIcons.calendar,
                win11IconPath: ImageAssets.win11CalendarPlus,
              ),
              SizedBox(width: 6.w),
              Text(
                isYearly ? yearName : monthName,
                style: TextStyle(
                  fontSize: 13.spMin,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(TablerIcons.chevron_down, size: 16.spMin),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget buildViewToggle(WidgetRef ref, bool isYearly) {
  final isDark = Theme.of(ref.context).brightness == Brightness.dark;

  return Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.grey800 : AppColors.grey200,
      borderRadius: BorderRadius.circular(20.r),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleOption(
          context: ref.context,
          ref: ref,
          label: 'Monthly',
          isSelected: !isYearly,
          onTap:
              () => ref.read(dashboardProvider.notifier).setYearlyView(false),
        ),
        _buildToggleOption(
          context: ref.context,
          ref: ref,
          label: 'Yearly',
          isSelected: isYearly,
          onTap: () => ref.read(dashboardProvider.notifier).setYearlyView(true),
        ),
      ],
    ),
  );
}

Widget _buildToggleOption({
  required BuildContext context,
  required WidgetRef ref,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20.r),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.spMin, vertical: 6.spMin),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.spMin,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    ),
  );
}

void _showMonthPicker(WidgetRef ref, DateTime currentMonth) {
  showDialog(
    context: ref.context,
    builder:
        (context) => _MonthPickerDialog(
          selectedMonth: currentMonth,
          onMonthSelected: (month) {
            ref.read(dashboardProvider.notifier).setSelectedMonth(month);
          },
        ),
  );
}

void _showYearPicker(WidgetRef ref, DateTime currentMonth) {
  showDialog(
    context: ref.context,
    builder:
        (context) => _YearPickerDialog(
          selectedYear: currentMonth.year,
          onYearSelected: (year) {
            ref.read(dashboardProvider.notifier).setSelectedYear(year);
          },
        ),
  );
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthSelected;

  const _MonthPickerDialog({
    required this.selectedMonth,
    required this.onMonthSelected,
  });

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedMonth.year;
    _selectedMonth = widget.selectedMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => _selectedYear--),
            icon: const Icon(TablerIcons.chevron_left),
          ),
          Text(
            '$_selectedYear',
            style: TextStyle(fontSize: 18.spMin, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedYear++),
            icon: const Icon(TablerIcons.chevron_right),
          ),
        ],
      ),
      content: SizedBox(
        width: 280.w,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.5,
          ),
          itemCount: 12,
          itemBuilder: (context, index) {
            final isSelected = index + 1 == _selectedMonth;
            final isFuture =
                _selectedYear > DateTime.now().year ||
                (_selectedYear == DateTime.now().year &&
                    index + 1 > DateTime.now().month);

            return InkWell(
              onTap:
                  isFuture
                      ? null
                      : () {
                        setState(() => _selectedMonth = index + 1);
                      },
              child: Container(
                margin: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    months[index],
                    style: TextStyle(
                      color:
                          isFuture
                              ? Colors.grey
                              : isSelected
                              ? Colors.white
                              : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onMonthSelected(DateTime(_selectedYear, _selectedMonth, 1));
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}

class _YearPickerDialog extends StatefulWidget {
  final int selectedYear;
  final Function(int) onYearSelected;

  const _YearPickerDialog({
    required this.selectedYear,
    required this.onYearSelected,
  });

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;
  late int _startYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedYear;
    // Show years from 5 years ago to current year
    _startYear = DateTime.now().year - 8;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(9, (index) => _startYear + index);

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => setState(() => _startYear -= 9),
            icon: const Icon(TablerIcons.chevron_left),
          ),
          Text(
            'Select Year',
            style: TextStyle(fontSize: 18.spMin, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed:
                _startYear + 9 <= currentYear
                    ? () => setState(() => _startYear += 9)
                    : null,
            icon: Icon(
              TablerIcons.chevron_right,
              color: _startYear + 9 <= currentYear ? null : Colors.grey,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 280.w,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2,
          ),
          itemCount: years.length,
          itemBuilder: (context, index) {
            final year = years[index];
            final isSelected = year == _selectedYear;
            final isFuture = year > currentYear;

            return InkWell(
              onTap:
                  isFuture
                      ? null
                      : () {
                        setState(() => _selectedYear = year);
                      },
              child: Container(
                margin: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color:
                        isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$year',
                    style: TextStyle(
                      color:
                          isFuture
                              ? Colors.grey
                              : isSelected
                              ? Colors.white
                              : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onYearSelected(_selectedYear);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
