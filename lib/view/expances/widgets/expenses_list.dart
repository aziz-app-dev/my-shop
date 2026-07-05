import 'package:desktopapp/res/components/empty_widget.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../../models/expense_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../view_models/providers/expense_provider.dart';
import '../widgets/expense_dialogs.dart';

Widget buildExpensesList(
  BuildContext context,
  WidgetRef ref,
  ExpenseState state,
  bool isDark,
) {
  final expenses = state.filteredExpenses;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          mdTextBold(text: 'Recent Expenses'),
          if (state.selectedCategoryFilter != null ||
              state.startDateFilter != null)
            TextButton.icon(
              onPressed:
                  () => ref.read(expenseProvider.notifier).clearFilters(),
              icon: Icon(TablerIcons.filter_off, size: 14.spMin),
              label: Text('Clear', style: TextStyle(fontSize: 12.spMin)),
            ),
        ],
      ),
      SizedBox(height: 8.h),
      if (expenses.isEmpty)
        Column(
          children: [
            SizedBox(height: 40.h),
            EmptyWidget1(message: "No expenses found"),
          ],
        )
      else
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: expenses.length,
          separatorBuilder: (_, __) => SizedBox(height: 8.h),
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _buildExpenseCard(context, ref, expense, isDark);
          },
        ),
    ],
  );
}

Widget _buildExpenseCard(
  BuildContext context,
  WidgetRef ref,
  Expense expense,
  bool isDark,
) {
  return Dismissible(
    key: Key(expense.id),
    direction: DismissDirection.endToStart,
    background: Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.only(right: 16.spMin),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      ),
      child: AppIcon(
        win11IconPath: ImageAssets.win11RecycleBin,
        defaultIcon: TablerIcons.trash,
      ),
    ),
    confirmDismiss: (_) => ExpenseDialogs.confirmDelete(context, ref, expense),
    child: Container(
      padding: EdgeInsets.all(12.spMin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.spMin),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm.r),
            ),
            child: AppIcon(
              win11IconPath: ImageAssets.win11Bill,
              defaultIcon: TablerIcons.receipt,
              color: AppColors.primary,
              size: 22.spMin,
            ),
          ),
          SizedBox(width: 10.spMin),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                smTextBold(text: expense.categoryName ?? 'Other'),
                if (expense.note != null && expense.note!.isNotEmpty)
                  smText(text: expense.note!, color: Colors.grey, maxLines: 1),
                xsText(
                  text: DateFormat('MMM dd, yyyy').format(expense.date),
                  color: Colors.grey,
                ),
              ],
            ),
          ),
          mdTextBold(
            text: 'Rs.${expense.amount.toStringAsFixed(2)}',
            color: Colors.red,
          ),
        ],
      ),
    ),
  );
}

Widget buildDesktopExpensesList(
  WidgetRef ref,
  ExpenseState state,
  bool isDark,
) {
  final expenses = state.filteredExpenses;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          lgTextBold(text: 'Recent Expenses'),
          if (state.selectedCategoryFilter != null ||
              state.startDateFilter != null)
            TextButton.icon(
              onPressed:
                  () => ref.read(expenseProvider.notifier).clearFilters(),
              icon: AppIcon(
                win11IconPath: ImageAssets.win11ClearFilter,
                defaultIcon: TablerIcons.filter_off,
                size: 16.spMin,
              ),
              label: mdText(text: 'Clear filters'),
            ),
        ],
      ),
      SizedBox(height: 16.h),
      if (expenses.isEmpty)
        Column(
          children: [
            SizedBox(height: 40.h),
            EmptyWidget1(message: "No expenses found"),
          ],
        )
      else
        // Grid layout for desktop
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 5.5.spMin,
            crossAxisSpacing: 12.spMin,
            mainAxisSpacing: 12.spMin,
          ),
          itemCount: expenses.length,
          itemBuilder: (context, index) {
            final expense = expenses[index];
            return _buildExpenseCard(context, ref, expense, isDark);
          },
        ),
    ],
  );
}
