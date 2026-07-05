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

/// Income vs Expenses+Shopping comparison chart
Widget buildComparisonChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildComparisonChartContent(context, state, animationValue);
    },
  );
}

Widget _buildComparisonChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dailySales = state.dailySalesTrend;
  final dailyOutflow = state.dailyOutflowTrend;
  final monthName = DateFormat('MMMM').format(state.selectedMonth);

  if (dailySales.isEmpty && dailyOutflow.isEmpty) {
    return _buildEmptyState(isDark, monthName);
  }

  // Calculate max value for Y axis
  final maxSales =
      dailySales.isEmpty
          ? 0.0
          : dailySales.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  final maxOutflow =
      dailyOutflow.isEmpty
          ? 0.0
          : dailyOutflow.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
  final maxY = (maxSales > maxOutflow ? maxSales : maxOutflow) * 1.2;

  // Create spots for both lines with animation
  final salesSpots =
      dailySales.asMap().entries.map((entry) {
        return FlSpot(
          entry.key.toDouble(),
          entry.value.amount * animationValue,
        );
      }).toList();

  final outflowSpots =
      dailyOutflow.asMap().entries.map((entry) {
        return FlSpot(
          entry.key.toDouble(),
          entry.value.amount * animationValue,
        );
      }).toList();

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
              defaultIcon: TablerIcons.chart_arrows_vertical,
              size: 20.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Income vs Outflow'),
          ],
        ),
        SizedBox(height: 8.spMin),
        // Legend
        Row(
          children: [
            _buildLegendItem('Income (Sales)', AppColors.success),
            SizedBox(width: 16.spMin),
            _buildLegendItem('Outflow (Expense+Purchase)', AppColors.error),
          ],
        ),
        SizedBox(height: 16.spMin),
        SizedBox(
          height: 280.spMin,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 8 : 8,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? AppColors.grey700 : AppColors.grey300,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 25.spMin,

                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox();
                      return Padding(
                        padding: EdgeInsets.only(right: 4.w),
                        child: Text(
                          _formatAmount(value),
                          style: TextStyle(
                            fontSize: 10.spMin,
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
                    reservedSize: 20.h,
                    interval: (dailySales.length / 10).ceil().toDouble(),
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= dailySales.length) return const SizedBox();
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          '${dailySales[index].date.day}',
                          style: TextStyle(
                            fontSize: 10.spMin,
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
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY > 0 ? maxY : 100,
              lineBarsData: [
                // Income (Sales) line - Green
                LineChartBarData(
                  spots: salesSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.success,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                // Outflow (Expenses + Shopping) line - Red
                LineChartBarData(
                  spots: outflowSpots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.error,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor:
                      (touchedSpot) =>
                          isDark ? AppColors.grey700 : Colors.white,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final day = dailySales[spot.x.toInt()].date;
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${isIncome ? 'Income' : 'Outflow'}\n${DateFormat('MMM d').format(day)}: Rs.${spot.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: isIncome ? AppColors.success : AppColors.error,
                          fontSize: 11.spMin,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),
        // Summary row
        _buildSummaryRow(state),
      ],
    ),
  );
}

Widget _buildLegendItem(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12.w,
        height: 3.h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2.r),
        ),
      ),
      SizedBox(width: 6.w),
      Text(label, style: TextStyle(fontSize: 10.spMin, color: Colors.grey)),
    ],
  );
}

Widget _buildSummaryRow(DashboardState state) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _buildSummaryItem(
        'Total Income',
        'Rs.${state.totalSalesThisMonth.toStringAsFixed(0)}',
        AppColors.success,
      ),
      _buildSummaryItem(
        'Total Outflow',
        'Rs.${state.totalOutflowThisMonth.toStringAsFixed(0)}',
        AppColors.error,
      ),
      _buildSummaryItem(
        'Net Balance',
        'Rs.${state.netProfit.toStringAsFixed(0)}',
        state.netProfit >= 0 ? AppColors.primary : AppColors.error,
      ),
    ],
  );
}

Widget _buildSummaryItem(String label, String value, Color color) {
  return Column(
    children: [
      Text(label, style: TextStyle(fontSize: 10.spMin, color: Colors.grey)),
      SizedBox(height: 2.h),
      Text(
        value,
        style: TextStyle(
          fontSize: 12.spMin,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    ],
  );
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
          defaultIcon: TablerIcons.chart_arrows_vertical,
          size: 48.spMin,
          color: Colors.grey,
        ),
        SizedBox(height: 12.h),
        mdText(text: 'No data for $monthName'),
        SizedBox(height: 4.h),
        smText(
          text: 'Income and expense data will appear here',
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
