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

/// Top selling items horizontal bar chart
Widget buildTopSellingItemsChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildTopSellingItemsChartContent(context, state, animationValue);
    },
  );
}

Widget _buildTopSellingItemsChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final items = state.topSellingItems;

  if (items.isEmpty) {
    return _buildEmptyChartState(isDark, 'No Sales Data', 'No items sold yet');
  }

  final maxQuantity =
      items
          .map((i) => i.quantitySold)
          .reduce((a, b) => a > b ? a : b)
          .toDouble();

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
              win11IconPath: ImageAssets.win11Stock,
              defaultIcon: TablerIcons.trending_up,
              size: 20.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Top Selling Items'),
            const Spacer(),
            smText(
              text: state.isYearlyView ? 'Yearly' : 'Monthly',
              color: Colors.grey,
            ),
          ],
        ),
        SizedBox(height: 16.spMin),
        SizedBox(
          height: 280.spMin,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxQuantity * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor:
                      (group) => isDark ? AppColors.grey700 : Colors.white,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = items[group.x.toInt()];
                    return BarTooltipItem(
                      '${item.name}\nSold: ${item.quantitySold}\nRevenue: Rs.${item.totalRevenue.toStringAsFixed(0)}',
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
                    reservedSize: 80.spMin,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= items.length) return const SizedBox();
                      return Padding(
                        padding: EdgeInsets.only(right: 8.spMin),
                        child: Text(
                          _truncateName(items[index].name, 12),
                          style: TextStyle(
                            fontSize: 10.spMin,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 25.h,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 9.spMin, color: Colors.grey),
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
                drawHorizontalLine: false,
                verticalInterval: maxQuantity / 4,
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: isDark ? AppColors.grey700 : AppColors.grey300,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups:
                  items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item.quantitySold.toDouble() * animationValue,
                          color: AppColors.primary,
                          width: 20.h,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(4.r),
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

/// Profit/Loss analysis chart showing profitable vs loss-making items
Widget buildProfitLossChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildProfitLossChartContent(context, state, animationValue);
    },
  );
}

Widget _buildProfitLossChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final items = state.mostProfitableItems;

  if (items.isEmpty) {
    return _buildEmptyChartState(
      isDark,
      'No Profit Data',
      'No sales to analyze',
    );
  }

  // Separate profitable and loss items
  final profitable = items.where((i) => i.totalProfit >= 0).toList();
  final loss = items.where((i) => i.totalProfit < 0).toList();
  final totalLoss = loss.fold(0.0, (sum, i) => sum + i.totalProfit.abs());

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
              defaultIcon: TablerIcons.report_analytics,
              size: 20.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Profit Analysis'),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.spMin,
                vertical: 4.spMin,
              ),
              decoration: BoxDecoration(
                color:
                    state.grossProfit >= 0
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                '${state.grossProfitMargin.toStringAsFixed(1)}% margin',
                style: TextStyle(
                  fontSize: 10.spMin,
                  fontWeight: FontWeight.bold,
                  color:
                      state.grossProfit >= 0
                          ? AppColors.success
                          : AppColors.error,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.spMin),
        // Gross profit summary
        Row(
          children: [
            Expanded(
              child: _buildProfitCard(
                isDark: isDark,
                label: 'Gross Profit',
                value: state.grossProfit * animationValue,
                icon: TablerIcons.arrow_up_right,
                color: AppColors.success,
              ),
            ),
            SizedBox(width: 12.spMin),
            Expanded(
              child: _buildProfitCard(
                isDark: isDark,
                label: 'Total Loss',
                value: totalLoss * animationValue,
                icon: TablerIcons.arrow_down_right,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.spMin),
        // Top profitable items
        if (profitable.isNotEmpty) ...[
          smText(text: 'Top Profitable Items', color: Colors.grey),
          SizedBox(height: 8.spMin),
          ...profitable
              .take(5)
              .map(
                (item) => _buildProfitItemRow(
                  isDark: isDark,
                  name: item.name,
                  profit: item.totalProfit * animationValue,
                  margin: item.profitMargin * animationValue,
                  isProfit: true,
                ),
              ),
        ],
        if (loss.isNotEmpty) ...[
          SizedBox(height: 12.spMin),
          smText(text: 'Loss-Making Items', color: Colors.grey),
          SizedBox(height: 8.spMin),
          ...loss
              .take(3)
              .map(
                (item) => _buildProfitItemRow(
                  isDark: isDark,
                  name: item.name,
                  profit: item.totalProfit * animationValue,
                  margin: item.profitMargin * animationValue,
                  isProfit: false,
                ),
              ),
        ],
      ],
    ),
  );
}

/// Category profit breakdown chart
Widget buildCategoryProfitChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1000),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildCategoryProfitChartContent(context, state, animationValue);
    },
  );
}

Widget _buildCategoryProfitChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final categories = state.profitByCategory;

  if (categories.isEmpty) {
    return _buildEmptyChartState(
      isDark,
      'No Category Data',
      'No sales to analyze',
    );
  }

  final totalProfit = categories.fold(0.0, (sum, c) => sum + c.profit);

  // Generate colors for categories
  final colors = [
    AppColors.primary,
    AppColors.success,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
    Colors.amber,
  ];

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
              defaultIcon: TablerIcons.category,
              size: 20.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.w),
            mdTextBold(text: 'Profit by Category'),
          ],
        ),
        SizedBox(height: 16.spMin),
        SizedBox(
          height: 280.spMin,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35.r,
                    sections:
                        categories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          final percentage =
                              totalProfit > 0
                                  ? (category.profit / totalProfit) * 100
                                  : 0.0;

                          return PieChartSectionData(
                            color: colors[index % colors.length],
                            value: category.profit.abs(),
                            title:
                                percentage > 5
                                    ? '${(percentage * animationValue).toStringAsFixed(0)}%'
                                    : '',
                            radius: 30.r * animationValue,
                            titleStyle: TextStyle(
                              fontSize: 10.spMin,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
              SizedBox(width: 12.spMin),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        categories.asMap().entries.map((entry) {
                          final index = entry.key;
                          final category = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 6.h),
                            child: Row(
                              children: [
                                Container(
                                  width: 10.spMin,
                                  height: 10.spMin,
                                  decoration: BoxDecoration(
                                    color: colors[index % colors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.spMin),
                                Expanded(
                                  child: Text(
                                    category.category,
                                    style: TextStyle(fontSize: 10.spMin),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'Rs.${category.profit.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 10.spMin,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        category.profit >= 0
                                            ? AppColors.success
                                            : AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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

/// Low stock alert widget
Widget buildLowStockAlert(BuildContext context, DashboardState state) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final lowStockItems = state.lowStockItems;

  if (lowStockItems.isEmpty) {
    return const SizedBox.shrink();
  }

  return Container(
    padding: EdgeInsets.all(16.spMin),
    decoration: BoxDecoration(
      color: isDark ? AppColors.grey800 : AppColors.grey100,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.spMin),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppIcon(
                win11IconPath: ImageAssets.win11Siren,
                defaultIcon: TablerIcons.alert_triangle,
                size: 18.spMin,
                color: AppColors.warning,
              ),
            ),
            SizedBox(width: 8.spMin),
            mdTextBold(text: 'Low Stock Alert'),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8.spMin,
                vertical: 2.spMin,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '${lowStockItems.length}',
                style: TextStyle(
                  fontSize: 11.spMin,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.spMin),
        ...lowStockItems
            .take(5)
            .map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: 8.spMin),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.name,
                        style: TextStyle(fontSize: 12.spMin),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              item.currentStock == 0
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          item.currentStock == 0
                              ? 'Out'
                              : '${item.currentStock} left',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.spMin,
                            fontWeight: FontWeight.bold,
                            color:
                                item.currentStock == 0
                                    ? AppColors.error
                                    : AppColors.warning,
                          ),
                        ),
                      ),
                    ),
                    if (item.daysUntilStockout != null) ...[
                      SizedBox(width: 8.w),
                      Text(
                        '~${item.daysUntilStockout}d',
                        style: TextStyle(
                          fontSize: 10.spMin,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        if (lowStockItems.length > 5)
          Center(
            child: Text(
              '+${lowStockItems.length - 5} more items',
              style: TextStyle(fontSize: 11.spMin, color: Colors.grey),
            ),
          ),
      ],
    ),
  );
}

/// Sales vs Stock trend comparison
Widget buildSalesStockTrendChart(BuildContext context, DashboardState state) {
  return AnimatedChartWrapper(
    duration: const Duration(milliseconds: 1200),
    curve: Curves.easeOutCubic,
    builder: (animationValue) {
      return _buildSalesStockTrendChartContent(context, state, animationValue);
    },
  );
}

Widget _buildSalesStockTrendChartContent(
  BuildContext context,
  DashboardState state,
  double animationValue,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final dailySales = state.dailySalesTrend;

  if (dailySales.isEmpty || dailySales.every((d) => d.amount == 0)) {
    return _buildEmptyChartState(
      isDark,
      'No Trend Data',
      'No sales data to show',
    );
  }

  final maxSales = dailySales
      .map((d) => d.amount)
      .reduce((a, b) => a > b ? a : b);

  return Container(
    padding: EdgeInsets.all(16.w),
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
              defaultIcon: TablerIcons.chart_area_line,
              size: 20.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 8.w),
            mdTextBold(text: 'Sales Trend'),
            const Spacer(),
            _buildTrendLegendItem('Daily Sales', AppColors.primary),
          ],
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 180.h,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxSales / 4,
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
                    reservedSize: 45.w,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatAmount(value),
                        style: TextStyle(fontSize: 9.spMin, color: Colors.grey),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 25.h,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      final day = value.toInt() + 1;
                      if (day > dailySales.length) return const SizedBox();
                      return Text(
                        '$day',
                        style: TextStyle(fontSize: 9.spMin, color: Colors.grey),
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
                  spots:
                      dailySales.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.amount * animationValue,
                        );
                      }).toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor:
                      (spot) => isDark ? AppColors.grey700 : Colors.white,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final day = spot.x.toInt() + 1;
                      return LineTooltipItem(
                        'Day $day\nRs.${spot.y.toStringAsFixed(0)}',
                        TextStyle(
                          color: isDark ? Colors.white : Colors.black,
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
      ],
    ),
  );
}

// ============ HELPER WIDGETS ============

Widget _buildEmptyChartState(bool isDark, String title, String subtitle) {
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
          defaultIcon: TablerIcons.chart_bar_off,
          size: 48.spMin,
          color: Colors.grey,
        ),
        SizedBox(height: 12.h),
        mdText(text: title),
        SizedBox(height: 4.h),
        smText(text: subtitle, color: Colors.grey),
      ],
    ),
  );
}

Widget _buildProfitCard({
  required bool isDark,
  required String label,
  required double value,
  required IconData icon,
  required Color color,
}) {
  return Container(
    padding: EdgeInsets.all(16.spMin),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.spMin, color: color),
            SizedBox(width: 4.spMin),
            Text(
              label,
              style: TextStyle(fontSize: 10.spMin, color: Colors.grey),
            ),
          ],
        ),
        SizedBox(height: 4.spMin),
        Text(
          'Rs.${value.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16.spMin,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}

Widget _buildProfitItemRow({
  required bool isDark,
  required String name,
  required double profit,
  required double margin,
  required bool isProfit,
}) {
  return Padding(
    padding: EdgeInsets.only(bottom: 6.spMin),
    child: Row(
      children: [
        Container(
          width: 6.spMin,
          height: 6.spMin,
          decoration: BoxDecoration(
            color: isProfit ? AppColors.success : AppColors.error,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8.spMin),
        Expanded(
          child: Text(
            name,
            style: TextStyle(fontSize: 11.spMin),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          '${isProfit ? '+' : ''}Rs.${profit.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 11.spMin,
            fontWeight: FontWeight.bold,
            color: isProfit ? AppColors.success : AppColors.error,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: (isProfit ? AppColors.success : AppColors.error).withValues(
              alpha: 0.1,
            ),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            '${margin.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 9.spMin,
              color: isProfit ? AppColors.success : AppColors.error,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildTrendLegendItem(String label, Color color) {
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
      SizedBox(width: 4.w),
      Text(label, style: TextStyle(fontSize: 10.spMin, color: Colors.grey)),
    ],
  );
}

String _truncateName(String name, int maxLength) {
  if (name.length <= maxLength) return name;
  return '${name.substring(0, maxLength - 2)}..';
}

String _formatAmount(double value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(0)}K';
  }
  return value.toStringAsFixed(0);
}
