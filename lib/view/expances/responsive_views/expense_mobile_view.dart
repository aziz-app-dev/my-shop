import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/colors/app_color.dart';
import '../../../view_models/providers/expense_provider.dart';
import '../widgets/expense_app_bar.dart';
import '../widgets/expense_dialogs.dart';
import '../widgets/expenses_list.dart';
import '../widgets/pie_chart.dart';
import '../widgets/summary_widget.dart';

class ExpenseMobileView extends ConsumerWidget {
  final VoidCallback openDrawer;

  const ExpenseMobileView({super.key, required this.openDrawer});

  // Colors for pie chart categories

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: ExpenseAppBar(isMobile: true, openDrawer: openDrawer),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => ExpenseDialogs.showAddExpenseDialog(
              context,
              ref,
              expenseState.categories,
            ),
        backgroundColor: AppColors.primary,
        child: const Icon(TablerIcons.plus, color: Colors.white),
      ),
      body:
          expenseState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => ref.read(expenseProvider.notifier).loadData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pie Chart Section
                      buildPieChartSection(expenseState, isDark, ref),
                      SizedBox(height: 16.h),

                      // Summary Cards
                      buildSummarySection(context, expenseState),
                      SizedBox(height: 16.h),

                      // Expenses List
                      buildExpensesList(context, ref, expenseState, isDark),
                    ],
                  ),
                ),
              ),
    );
  }
}
