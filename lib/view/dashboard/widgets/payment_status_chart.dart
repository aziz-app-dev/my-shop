import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../utils/app_sizes.dart';
import '../../../view_models/states/dashboard_state.dart';
import 'animated_chart_wrapper.dart';

/// Payment & Expense status chart showing received, pending, and expenses
Widget buildPaymentStatusChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildPaymentStatusChartContent(context, state, animationValue);
    },
  );
}

Widget _buildPaymentStatusChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isYearly = state.isYearlyView;

  final received =
      isYearly ? state.totalReceivedThisYear : state.totalReceivedThisMonth;
  final pending =
      isYearly ? state.totalPendingThisYear : state.totalPendingThisMonth;
  final expenses =
      isYearly ? state.totalExpensesThisYear : state.totalExpensesThisMonth;
  final total = received + pending + expenses;

  if (total == 0) {
    return _buildEmptyState(isDark, isYearly, 'No financial data');
  }

  final receivedPercentage = (received / total) * 100;
  final pendingPercentage = (pending / total) * 100;
  final expensesPercentage = (expenses / total) * 100;

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
              win11IconPath: ImageAssets.win11Accounting,
              defaultIcon: TablerIcons.report_money,
              size: 20.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Financial Overview'),
            const Spacer(),
            smText(text: isYearly ? 'Yearly' : 'Monthly', color: Colors.grey),
          ],
        ),
        SizedBox(height: 16.spMin),
        SizedBox(
          height: 280.spMin,
          child: Row(
            children: [
              // Donut Chart
              Expanded(
                flex: 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 35.r,
                    sections: [
                      if (received > 0)
                        PieChartSectionData(
                          color: AppColors.success,
                          value: received,
                          title:
                              '${(receivedPercentage * animationValue).toStringAsFixed(0)}%',
                          radius: 32.r * animationValue,
                          titleStyle: TextStyle(
                            fontSize: 10.spMin,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (pending > 0)
                        PieChartSectionData(
                          color: AppColors.warning,
                          value: pending,
                          title:
                              '${(pendingPercentage * animationValue).toStringAsFixed(0)}%',
                          radius: 32.r * animationValue,
                          titleStyle: TextStyle(
                            fontSize: 10.spMin,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      if (expenses > 0)
                        PieChartSectionData(
                          color: AppColors.error,
                          value: expenses,
                          title:
                              '${(expensesPercentage * animationValue).toStringAsFixed(0)}%',
                          radius: 32.r * animationValue,
                          titleStyle: TextStyle(
                            fontSize: 10.spMin,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Legend & Details
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem(
                      color: AppColors.success,
                      label: 'Received',
                      value: 'Rs.${received.toStringAsFixed(0)}',
                      percentage: receivedPercentage,
                    ),
                    SizedBox(height: 10.h),
                    _buildLegendItem(
                      color: AppColors.warning,
                      label: 'Pending',
                      value: 'Rs.${pending.toStringAsFixed(0)}',
                      percentage: pendingPercentage,
                    ),
                    SizedBox(height: 10.h),
                    _buildLegendItem(
                      color: AppColors.error,
                      label: 'Expenses',
                      value: 'Rs.${expenses.toStringAsFixed(0)}',
                      percentage: expensesPercentage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Monthly breakdown bar chart for yearly view
Widget buildMonthlyBreakdownChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildMonthlyBreakdownChartContent(context, state, animationValue);
    },
  );
}

Widget _buildMonthlyBreakdownChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final monthlyData = state.monthlyBreakdown;

  final maxValue = monthlyData
      .map((m) => m.sales > m.expenses ? m.sales : m.expenses)
      .reduce((a, b) => a > b ? a : b);

  if (maxValue == 0) {
    return _buildEmptyState(isDark, true);
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
              win11IconPath: ImageAssets.win11ProfitReport,
              defaultIcon: TablerIcons.chart_bar,
              size: 20.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Monthly Breakdown ${state.selectedMonth.year}'),
          ],
        ),
        SizedBox(height: 8.spMin),
        // Legend
        Row(
          children: [
            _buildBarLegendItem('Sales', AppColors.success),
            SizedBox(width: 16.w),
            _buildBarLegendItem('Expenses', AppColors.error),
          ],
        ),
        SizedBox(height: 16.spMin),
        SizedBox(
          height: 280.h,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor:
                      (group) => isDark ? AppColors.grey700 : Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = monthlyData[group.x.toInt()];
                    final value = rodIndex == 0 ? month.sales : month.expenses;
                    final label = rodIndex == 0 ? 'Sales' : 'Expenses';
                    return BarTooltipItem(
                      '${month.monthName}\n$label: Rs.${value.toStringAsFixed(0)}',
                      TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 11.spMin,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 45.spMin,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8.spMin),
                        child: Text(
                          _formatAmount(value),
                          style: TextStyle(
                            fontSize: 9.spMin,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30.h,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= monthlyData.length) return const SizedBox();
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          monthlyData[index].monthName,
                          style: TextStyle(
                            fontSize: 8.spMin,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxValue / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? AppColors.grey700 : AppColors.grey300,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups:
                  monthlyData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data.sales * animationValue,
                          color: AppColors.success,
                          width: 8.w,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(2.r),
                          ),
                        ),
                        BarChartRodData(
                          toY: data.expenses * animationValue,
                          color: AppColors.error,
                          width: 8.w,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(2.r),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildLegendItem({
  required Color color,
  required String label,
  required String value,
  required double percentage,
}) {
  return Row(
    children: [
      Container(
        width: 12.w,
        height: 12.h,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      SizedBox(width: 8.w),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12.spMin, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildBarLegendItem(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12.w,
        height: 8.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
      SizedBox(width: 4.w),
      Text(label, style: TextStyle(fontSize: 10.spMin, color: Colors.grey)),
    ],
  );
}

Widget _buildEmptyState(bool isDark, bool isYearly, [String? message]) {
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
        mdText(text: message ?? 'No payment data'),
        SizedBox(height: 4.h),
        smText(
          text:
              isYearly
                  ? 'No transactions this year'
                  : 'No transactions this month',
          color: Colors.grey,
        ),
      ],
    ),
  );
}

String _formatAmount(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }
  return value.toStringAsFixed(0);
}
