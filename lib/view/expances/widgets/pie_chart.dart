import 'package:desktopapp/utils/app_sizes.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../view_models/providers/expense_provider.dart';
import '../widgets/date_slecter.dart';

/// ================= PIE CHART SECTION =================

Widget buildPieChartSection(ExpenseState state, bool isDark, WidgetRef ref) {
  final expensesByCategory = state.expensesByCategory;
  final total = state.currentMonthTotal;
  final monthName = DateFormat('MMMM yyyy').format(state.selectedMonth);
  final expenseState = ref.watch(expenseProvider);

  /// ---------- EMPTY STATE ----------
  if (expensesByCategory.isEmpty) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.spMin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: buildMonthSelector(ref, expenseState),
          ),
          AppIcon(
            win11IconPath: ImageAssets.win11ResultsFound,
            defaultIcon: TablerIcons.chart_pie_off,
            size: 48.spMin,
            color: Colors.grey,
          ),
          SizedBox(height: 12.h),
          mdText(text: 'No expenses for $monthName'),
          SizedBox(height: 8.h),
          smText(
            text: 'Add your first expense to see the chart',
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  /// ---------- CHART STATE ----------
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(10.spMin),
    decoration: BoxDecoration(
      color: isDark ? AppColors.grey800 : AppColors.grey100,
      borderRadius: BorderRadius.circular(16.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildMonthSelector(ref, expenseState),
            mdTextBold(
              text: 'Rs.${total.toStringAsFixed(2)}',
              color: AppColors.primary,
            ),
          ],
        ),

        SizedBox(height: 16.h),

        /// Dynamic Chart Area
        LayoutBuilder(
          builder: (context, constraints) {
            /// Dynamic height based on available width
            final double chartHeight = constraints.maxWidth * 0.55;

            return SizedBox(
              height: chartHeight,
              child: Row(
                children: [
                  /// Pie Chart
                  Expanded(
                    flex: 1,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: chartHeight * 0.18,
                          sections: _buildPieChartSections(
                            expensesByCategory,
                            total,
                            chartHeight,
                          ),
                        ),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOutCubic,
                      ),
                    ),
                  ),

                  SizedBox(width: 12.w),

                  /// Legend
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildLegend(expensesByCategory),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  );
}

/// ================= PIE SECTIONS =================

List<PieChartSectionData> _buildPieChartSections(
  Map<String, double> expensesByCategory,
  double total,
  double chartSize,
) {
  final entries = expensesByCategory.entries.toList();

  return entries.asMap().entries.map((entry) {
    final index = entry.key;
    final amount = entry.value.value;
    final percentage = (amount / total) * 100;

    return PieChartSectionData(
      color: AppColors.chartColors[index % AppColors.chartColors.length],
      value: amount,
      title: '${percentage.toStringAsFixed(0)}%',
      radius: chartSize * 0.25,
      titleStyle: TextStyle(
        fontSize: chartSize * 0.06,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }).toList();
}

/// ================= LEGEND =================

List<Widget> _buildLegend(Map<String, double> expensesByCategory) {
  final entries = expensesByCategory.entries.toList();

  return entries.asMap().entries.map((entry) {
    final index = entry.key;
    final category = entry.value.key;
    final amount = entry.value.value;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
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
          Expanded(child: smText(text: category, maxLines: 1)),
          smText(text: 'Rs.${amount.toStringAsFixed(0)}'),
        ],
      ),
    );
  }).toList();
}
