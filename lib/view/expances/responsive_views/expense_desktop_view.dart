import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../view_models/providers/expense_provider.dart';
import '../widgets/expense_app_bar.dart';
import '../widgets/expenses_list.dart';
import '../widgets/pie_chart.dart';
import '../widgets/summary_widget.dart';

class ExpenseDesktopView extends ConsumerWidget {
  final VoidCallback? openDrawer;

  const ExpenseDesktopView({super.key, this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const ExpenseAppBar(isMobile: false),
      body:
          expenseState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => ref.read(expenseProvider.notifier).loadData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(16.spMin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Section: Pie Chart and Summary Cards side by side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pie Chart Section
                          Expanded(
                            flex: 3,
                            child: buildPieChartSection(
                              expenseState,
                              isDark,
                              ref,
                            ),
                          ),
                          SizedBox(width: 16.spMin),
                          // Summary Cards
                          Expanded(
                            flex: 2,
                            child: buildSummaryDesktopSection(
                              context,
                              expenseState,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // Expenses List
                      buildDesktopExpensesList(ref, expenseState, isDark),
                    ],
                  ),
                ),
              ),
    );
  }
}
