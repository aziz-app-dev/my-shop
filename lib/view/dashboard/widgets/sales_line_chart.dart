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

Widget buildSalesLineChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildSalesLineChartContent(context, state, animationValue);
    },
  );
}

Widget _buildSalesLineChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dailySales = state.dailySalesTrend;
  final monthName = DateFormat('MMMM').format(state.selectedMonth);

  if (dailySales.isEmpty || state.totalSalesThisMonth == 0) {
    return _buildEmptyState(isDark, monthName);
  }

  final maxSales = dailySales
      .map((e) => e.amount)
      .reduce((a, b) => a > b ? a : b);
  final spots =
      dailySales.asMap().entries.map((entry) {
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
              win11IconPath: ImageAssets.win11Graph,
              defaultIcon: TablerIcons.chart_line,
              size: 20.spMin,
              color: AppColors.success,
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Daily Sales Trend'),
            const Spacer(),
            smText(
              text: '${state.totalTransactions} transactions',
              color: Colors.grey,
            ),
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
                horizontalInterval: maxSales > 0 ? maxSales / 4 : 1,
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
                    reservedSize: 50.w,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox();
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
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
                    reservedSize: 30.h,
                    interval: (dailySales.length / 6).ceil().toDouble(),
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
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: AppColors.success,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 3,
                        color: AppColors.success,
                        strokeWidth: 1,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.success.withValues(alpha: 0.3),
                        AppColors.success.withValues(alpha: 0.0),
                      ],
                    ),
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
                      return LineTooltipItem(
                        '${DateFormat('MMM d').format(day)}\nRs.${spot.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 12.spMin,
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
      ],
    ),
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
          defaultIcon: TablerIcons.chart_line,
          size: 48.spMin,
          color: Colors.grey,
        ),
        SizedBox(height: 12.h),
        mdText(text: 'No sales data for $monthName'),
        SizedBox(height: 4.h),
        smText(
          text: 'Sales will appear here when transactions are made',
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
