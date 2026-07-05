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

Widget buildCustomerBarChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildCustomerBarChartContent(context, state, animationValue);
    },
  );
}

Widget _buildCustomerBarChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final topCustomers = state.topCustomersByRevenue.take(5).toList();

  if (topCustomers.isEmpty) {
    return _buildEmptyState(isDark);
  }

  final maxRevenue = topCustomers.first.totalRevenue;

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
              win11IconPath: ImageAssets.win11People,
              defaultIcon: TablerIcons.users,
              size: 20.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Top Customers'),
            const Spacer(),
            smText(text: '${state.totalCustomers} total', color: Colors.grey),
          ],
        ),
        SizedBox(height: 16.spMin),
        SizedBox(
          height: 280.spMin,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxRevenue * 0.99,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor:
                      (group) => isDark ? AppColors.grey700 : Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final customer = topCustomers[group.x.toInt()];
                    return BarTooltipItem(
                      '${customer.name}\nRs.${customer.totalRevenue.toStringAsFixed(0)}\n${customer.transactionCount} orders',
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
                    reservedSize: 25.w,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: EdgeInsets.only(right: 4.w),
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
                    reservedSize: 20.h,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= topCustomers.length) return const SizedBox();
                      final name = topCustomers[index].name;
                      final displayName =
                          name.length > 8 ? '${name.substring(0, 8)}...' : name;
                      return Padding(
                        padding: EdgeInsets.only(top: 8.h),
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 9.spMin,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
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
                horizontalInterval: maxRevenue / 7,
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
                  topCustomers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final customer = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: customer.totalRevenue * animationValue,
                          color:
                              AppColors.chartColors[index %
                                  AppColors.chartColors.length],
                          width: 20.w,
                          borderRadius: BorderRadius.all(Radius.circular(4.r)),
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

Widget _buildEmptyState(bool isDark) {
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
          win11IconPath: ImageAssets.win11FindUser,
          defaultIcon: TablerIcons.users_minus,
          size: 48.spMin,
          color: Colors.grey,
        ),
        SizedBox(height: 12.h),
        mdText(text: 'No customer data'),
        SizedBox(height: 4.h),
        smText(text: 'Customer sales will appear here', color: Colors.grey),
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
