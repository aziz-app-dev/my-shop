import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../view_models/providers/dashboard_provider.dart';
import '../widgets/comparison_chart.dart';
import '../widgets/customer_bar_chart.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/opctions_toggle.dart';
import '../widgets/payment_status_chart.dart';
import '../widgets/sales_line_chart.dart';
import '../widgets/summary_cards.dart';
import '../widgets/trend_charts.dart';

class DashboardMobileView extends ConsumerWidget {
  final VoidCallback openDrawer;

  const DashboardMobileView({super.key, required this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: DashboardAppBar(isMobile: true, openDrawer: openDrawer),
      body:
          dashboardState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(12.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ! mounth and year toggle
                      toggleRow(ref),
                      SizedBox(height: 15.h),
                      // Summary Cards (2x2 Grid)
                      buildMobileSummaryCards(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Payment Status Chart (Received vs Pending)
                      buildPaymentStatusChart(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Sales Line Chart
                      buildSalesLineChart(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Expense Pie Chart
                      buildExpensePieChart(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Customer Bar Chart
                      buildCustomerBarChart(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Income vs Outflow Comparison Chart
                      buildComparisonChart(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Monthly Breakdown Chart (only for yearly view)
                      if (dashboardState.isYearlyView) ...[
                        buildMonthlyBreakdownChart(context, dashboardState),
                        SizedBox(height: 16.h),
                      ],

                      // Top Selling Items Chart
                      buildTopSellingItemsChart(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Profit/Loss Analysis Chart
                      buildProfitLossChart(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Category Profit Chart
                      buildCategoryProfitChart(context, dashboardState),
                      SizedBox(height: 16.h),

                      // Low Stock Alert
                      buildLowStockAlert(context, dashboardState),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
    );
  }
}
