import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../utils/app_sizes.dart';
import '../../../view_models/states/dashboard_state.dart';
import 'animated_chart_wrapper.dart';

Widget buildExpensePieChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildExpensePieChartContent(context, state, animationValue);
    },
  );
}

Widget _buildExpensePieChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final expensesByCategory = state.expensesByCategory;
  final total = state.totalExpensesThisMonth;
  final monthName = DateFormat('MMMM').format(state.selectedMonth);

  if (expensesByCategory.isEmpty) {
    return _buildEmptyState(isDark, monthName);
  }

  return Container(
    padding: EdgeInsets.all(16.spMin),
    decoration: BoxDecoration(
      color: isDark ? AppColors.grey800 : AppColors.grey100,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppIcon(
              win11IconPath: ImageAssets.win11Invoice,
              defaultIcon: TablerIcons.chart_pie,
              size: 20.spMin,
              color: AppColors.error,
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Expenses by Category'),
            const Spacer(),
            smText(
              text: 'Rs.${total.toStringAsFixed(0)}',
              color: AppColors.error,
            ),
          ],
        ),
        SizedBox(height: 16.spMin),
        SizedBox(
          height: 280.spMin,
          child: Row(
            children: [
              // Pie Chart
              Expanded(
                flex: 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35.r,
                    sections: _buildPieSections(
                      expensesByCategory,
                      total,
                      animationValue,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.spMin),
              // Legend
              Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegend(expensesByCategory, total),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

List<PieChartSectionData> _buildPieSections(
  Map<String, double> expensesByCategory,
  double total,
  double animationValue,
) {
  final entries =
      expensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  return entries.asMap().entries.map((entry) {
    final index = entry.key;
    final amount = entry.value.value;
    final percentage = (amount / total) * 100;

    return PieChartSectionData(
      color: AppColors.chartColors[index % AppColors.chartColors.length],
      value: amount,
      title: '${(percentage * animationValue).toStringAsFixed(0)}%',
      radius: 45.r * animationValue,
      titleStyle: TextStyle(
        fontSize: 10.spMin,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }).toList();
}

List<Widget> _buildLegend(
  Map<String, double> expensesByCategory,
  double total,
) {
  final entries =
      expensesByCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  return entries.asMap().entries.map((entry) {
    final index = entry.key;
    final category = entry.value.key;
    final amount = entry.value.value;
    final percentage = (amount / total) * 100;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.h,
            decoration: BoxDecoration(
              color:
                  AppColors.chartColors[index % AppColors.chartColors.length],
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              category,
              style: TextStyle(fontSize: 11.spMin),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 11.spMin,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }).toList();
}

Widget _buildEmptyState(bool isDark, String monthName) {
  return Container(
    padding: EdgeInsets.all(16.w),
    decoration: BoxDecoration(
      color: isDark ? AppColors.grey800 : AppColors.grey100,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(
          win11IconPath: ImageAssets.win11ResultsFound,
          defaultIcon: TablerIcons.chart_pie_off,
          size: 48.spMin,
          color: Colors.grey,
        ),
        SizedBox(height: 12.h),
        mdText(text: 'No expenses for $monthName'),
        SizedBox(height: 4.h),
        smText(text: 'Expenses will appear here', color: Colors.grey),
      ],
    ),
  );
}
