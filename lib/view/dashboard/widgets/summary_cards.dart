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

/// Build summary cards for mobile (2x2 grid + inventory row)
Widget buildMobileSummaryCards(BuildContext context, DashboardState state) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isYearly = state.isYearlyView;

  // Get values based on view type
  final totalSales =
      isYearly ? state.totalSalesThisYear : state.totalSalesThisMonth;
  final totalExpenses =
      isYearly ? state.totalExpensesThisYear : state.totalExpensesThisMonth;
  final grossProfit = state.grossProfit; // Uses isYearlyView internally
  final received =
      isYearly ? state.totalReceivedThisYear : state.totalReceivedThisMonth;
  final pending =
      isYearly ? state.totalPendingThisYear : state.totalPendingThisMonth;

  return Column(
    children: [
      // Financial Cards Row 1: Sales & Expenses
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.currency_dollar,
              win11Icon: ImageAssets.win11DollarBag,
              title: 'Total Sales',
              value: 'Rs.${totalSales.toStringAsFixed(0)}',
              numericValue: totalSales,
              prefix: 'Rs.',
              change: isYearly ? null : state.salesPercentageChange,
              color: AppColors.success,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.receipt,
              win11Icon: ImageAssets.win11Invoice,
              title: 'Expenses',
              value: 'Rs.${totalExpenses.toStringAsFixed(0)}',
              numericValue: totalExpenses,
              prefix: 'Rs.',
              change: isYearly ? null : state.expensePercentageChange,
              color: AppColors.error,
              isExpense: true,
            ),
          ),
        ],
      ),
      SizedBox(height: 10.h),
      // Financial Cards Row 2: Received & Pending
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.cash,
              win11Icon: ImageAssets.win11Cash,
              title: 'Received',
              value: 'Rs.${received.toStringAsFixed(0)}',
              numericValue: received,
              prefix: 'Rs.',
              color: AppColors.success,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.clock_dollar,
              win11Icon: ImageAssets.win11Bill,
              title: 'Pending',
              value: 'Rs.${pending.toStringAsFixed(0)}',
              numericValue: pending,
              prefix: 'Rs.',
              color: AppColors.warning,
            ),
          ),
        ],
      ),
      SizedBox(height: 10.h),
      // Financial Cards Row 3: Profit (Selling Price - Purchase Price)
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.chart_line,
              win11Icon: ImageAssets.win11Graph,
              title: 'Profit',
              value: 'Rs.${grossProfit.toStringAsFixed(0)}',
              numericValue: grossProfit,
              prefix: 'Rs.',
              change: isYearly ? null : state.grossProfitPercentageChange,
              color: grossProfit >= 0 ? AppColors.primary : AppColors.error,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.users,
              win11Icon: ImageAssets.win11People,
              title: 'Customers',
              value: '${state.totalCustomers}',
              numericValue: state.totalCustomers.toDouble(),
              color: Colors.indigo,
            ),
          ),
        ],
      ),
      SizedBox(height: 10.h),
      // Inventory Cards Row
      Row(
        children: [
          Expanded(
            child: _buildCompactCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.package,
              win11Icon: ImageAssets.win11OpenBox,
              title: 'Products',
              value: '${state.totalProducts}',
              numericValue: state.totalProducts,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildCompactCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.tools,
              win11Icon: ImageAssets.win11Service,
              title: 'Services',
              value: '${state.totalServices}',
              numericValue: state.totalServices,
              color: Colors.purple,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _buildCompactCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.stack_2,
              win11Icon: ImageAssets.win11Stock,
              title: 'Total Stock',
              value: '${state.totalStock}',
              numericValue: state.totalStock,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    ],
  );
}

/// Build summary cards for desktop (horizontal rows)
Widget buildDesktopSummaryCards(BuildContext context, DashboardState state) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isYearly = state.isYearlyView;

  // Get values based on view type
  final totalSales =
      isYearly ? state.totalSalesThisYear : state.totalSalesThisMonth;
  final totalExpenses =
      isYearly ? state.totalExpensesThisYear : state.totalExpensesThisMonth;
  final grossProfit = state.grossProfit; // Uses isYearlyView internally
  final received =
      isYearly ? state.totalReceivedThisYear : state.totalReceivedThisMonth;
  final pending =
      isYearly ? state.totalPendingThisYear : state.totalPendingThisMonth;

  return Column(
    children: [
      // Financial Cards Row 1
      Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.currency_dollar,
              win11Icon: ImageAssets.win11DollarBag,
              title: 'Total Sales',
              value: 'Rs.${totalSales.toStringAsFixed(0)}',
              numericValue: totalSales,
              prefix: 'Rs.',
              change: isYearly ? null : state.salesPercentageChange,
              color: AppColors.success,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.cash,
              win11Icon: ImageAssets.win11Cash,
              title: 'Received',
              value: 'Rs.${received.toStringAsFixed(0)}',
              numericValue: received,
              prefix: 'Rs.',
              color: AppColors.success,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.clock_dollar,
              win11Icon: ImageAssets.win11Bill,
              title: 'Pending',
              value: 'Rs.${pending.toStringAsFixed(0)}',
              numericValue: pending,
              prefix: 'Rs.',
              color: AppColors.warning,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.receipt,
              win11Icon: ImageAssets.win11Invoice,
              title: 'Expenses',
              value: 'Rs.${totalExpenses.toStringAsFixed(0)}',
              numericValue: totalExpenses,
              prefix: 'Rs.',
              change: isYearly ? null : state.expensePercentageChange,
              color: AppColors.error,
              isExpense: true,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildSummaryCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.chart_line,
              win11Icon: ImageAssets.win11Graph,
              title: 'Profit',
              value: 'Rs.${grossProfit.toStringAsFixed(0)}',
              numericValue: grossProfit,
              prefix: 'Rs.',
              change: isYearly ? null : state.grossProfitPercentageChange,
              color: grossProfit >= 0 ? AppColors.primary : AppColors.error,
            ),
          ),
        ],
      ),
      SizedBox(height: 12.h),
      // Inventory Cards Row
      Row(
        children: [
          Expanded(
            child: _buildCompactCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.package,
              win11Icon: ImageAssets.win11OpenBox,
              title: 'Products',
              value: '${state.totalProducts}',
              numericValue: state.totalProducts,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildCompactCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.tools,
              win11Icon: ImageAssets.win11Service,
              title: 'Services',
              value: '${state.totalServices}',
              numericValue: state.totalServices,
              color: Colors.purple,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildCompactCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.stack_2,
              win11Icon: ImageAssets.win11Stock,
              title: 'Total Stock',
              value: '${state.totalStock}',
              numericValue: state.totalStock,
              color: Colors.teal,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildCompactCard(
              context: context,
              isDark: isDark,
              icon: TablerIcons.users,
              win11Icon: ImageAssets.win11People,
              title: 'Customers',
              value: '${state.totalCustomers}',
              numericValue: state.totalCustomers,
              color: Colors.indigo,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _buildSummaryCard({
  required BuildContext context,
  required bool isDark,
  required IconData icon,
  required String win11Icon,
  required String title,
  required String value,
  required Color color,
  double? change,
  bool isExpense = false,
  double? numericValue,
  String prefix = '',
}) {
  return Container(
    padding: EdgeInsets.all(AppSizes.tFVerPadding.spMin),
    decoration: BoxDecoration(
      color: isDark ? AppColors.grey800 : AppColors.grey100,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.spMin),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: AppIcon(
                win11IconPath: win11Icon,
                defaultIcon: icon,
                color: color,
                size: 26.spMin,
              ),
            ),
            SizedBox(width: 16.spMin),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  smText(text: title, color: Colors.grey),
                  SizedBox(height: 2.h),
                  numericValue != null
                      ? AnimatedValue(
                        value: numericValue,
                        duration: const Duration(milliseconds: 1000),
                        builder: (animatedVal) {
                          return mdTextBold(
                            text: '$prefix${animatedVal.toStringAsFixed(0)}',
                          );
                        },
                      )
                      : mdTextBold(text: value),
                ],
              ),
            ),
          ],
        ),
        if (change != null && change != 0) ...[
          SizedBox(height: 8.h),
          _buildChangeIndicator(change, isExpense),
        ],
      ],
    ),
  );
}

/// Compact card for inventory items (no change indicator)
Widget _buildCompactCard({
  required BuildContext context,
  required bool isDark,
  required IconData icon,
  required String win11Icon,
  required String title,
  required String value,
  required Color color,
  int? numericValue,
}) {
  return Container(
    padding: EdgeInsets.all(16.spMin),
    decoration: BoxDecoration(
      color: isDark ? AppColors.grey800 : AppColors.grey100,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.spMin),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: AppIcon(
            win11IconPath: win11Icon,
            defaultIcon: icon,
            color: color,
            size: 18.spMin,
          ),
        ),
        SizedBox(width: 16.spMin),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              smText(text: title, color: Colors.grey),
              numericValue != null
                  ? AnimatedValue(
                    value: numericValue.toDouble(),
                    duration: const Duration(milliseconds: 1000),
                    builder: (animatedVal) {
                      return mdTextBold(text: animatedVal.toStringAsFixed(0));
                    },
                  )
                  : mdTextBold(text: value),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildChangeIndicator(double change, bool isExpense) {
  // For expenses, positive change is bad, negative is good
  final isPositive = isExpense ? change < 0 : change > 0;
  final color = isPositive ? AppColors.success : AppColors.error;
  final icon =
      change >= 0 ? TablerIcons.trending_up : TablerIcons.trending_down;
  final displayChange = change.abs();

  return Row(
    children: [
      Icon(icon, size: 14.spMin, color: color),
      SizedBox(width: 4.w),
      Text(
        '${displayChange.toStringAsFixed(1)}% vs last month',
        style: TextStyle(
          fontSize: 11.spMin,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}
