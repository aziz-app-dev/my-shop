import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../view_models/providers/expense_provider.dart';

Widget buildSummarySection(BuildContext context, ExpenseState state) {
  final thisMonthTotal = state.currentMonthTotal;
  final expenseCount = state.currentMonthExpenses.length;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final avgExpense = expenseCount > 0 ? thisMonthTotal / expenseCount : 0.0;

  return Column(
    spacing: 10.h,
    children: [
      Row(
        spacing: 10.h,
        children: [
          Expanded(
            child: _buildSummaryCard(
              isDark: isDark,
              icon: TablerIcons.receipt,
              win11Icon: ImageAssets.win11ProfitReport,
              title: 'This Month',
              value: 'Rs.${thisMonthTotal.toStringAsFixed(2)}',
              color: AppColors.primary,
            ),
          ),
          Expanded(
            child: _buildSummaryCard(
              isDark: isDark,
              icon: TablerIcons.list_numbers,
              win11Icon: ImageAssets.win11List2,
              title: 'Transactions',
              value: expenseCount.toString(),
              color: Colors.orange,
            ),
          ),
        ],
      ),
      _buildSummaryCard(
        isDark: isDark,
        icon: TablerIcons.calculator,
        win11Icon: ImageAssets.win11Accounting,
        title: 'Average Expense',
        value: 'Rs.${avgExpense.toStringAsFixed(2)}',
        color: Colors.teal,
      ),
    ],
  );
}

Widget buildSummaryDesktopSection(BuildContext context, ExpenseState state) {
  final thisMonthTotal = state.currentMonthTotal;
  final expenseCount = state.currentMonthExpenses.length;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final avgExpense = expenseCount > 0 ? thisMonthTotal / expenseCount : 0.0;

  return Column(
    spacing: 19.h,
    children: [
      _buildSummaryCard(
        isDark: isDark,
        icon: TablerIcons.receipt,
        win11Icon: ImageAssets.win11ProfitReport,
        title: 'This Month',
        value: 'Rs.${thisMonthTotal.toStringAsFixed(2)}',
        color: AppColors.primary,
      ),
      _buildSummaryCard(
        isDark: isDark,
        icon: TablerIcons.list_numbers,
        win11Icon: ImageAssets.win11List2,
        title: 'Transactions',
        value: expenseCount.toString(),
        color: Colors.orange,
      ),
      _buildSummaryCard(
        isDark: isDark,
        icon: TablerIcons.calculator,
        win11Icon: ImageAssets.win11Accounting,
        title: 'Average Expense',
        value: 'Rs.${avgExpense.toStringAsFixed(2)}',
        color: Colors.teal,
      ),
    ],
  );
}

Widget _buildSummaryCard({
  required bool isDark,
  required IconData icon,
  required String win11Icon,
  required String title,
  required String value,
  required Color color,
}) {
  return Container(
    padding: EdgeInsets.all(AppSizes.tFVerPadding.spMin),
    decoration: BoxDecoration(
      color: isDark ? AppColors.grey800 : AppColors.grey100,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Column(
      spacing: 12.h,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 4.w,
          children: [
            AppIcon(
              win11IconPath: win11Icon,
              defaultIcon: icon,
              color: color,
              size: 20.spMin,
            ),
            mdTextBold(text: title),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: 2.w),
          child: mdText(text: value),
        ),
      ],
    ),
  );
}
