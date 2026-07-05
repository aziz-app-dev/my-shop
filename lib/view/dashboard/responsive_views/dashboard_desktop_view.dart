import 'package:desktopapp/view/dashboard/widgets/opctions_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../view_models/providers/dashboard_provider.dart';
import '../widgets/comparison_chart.dart';
import '../widgets/customer_bar_chart.dart';
import '../widgets/dashboard_app_bar.dart';
import '../widgets/expense_pie_chart.dart';
import '../widgets/payment_status_chart.dart';
import '../widgets/sales_line_chart.dart';
import '../widgets/summary_cards.dart';
import '../widgets/trend_charts.dart';

class DashboardDesktopView extends ConsumerWidget {
  final VoidCallback? openDrawer;

  const DashboardDesktopView({super.key, this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: const DashboardAppBar(isMobile: false),
      body:
          dashboardState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.spMin,
                    vertical: 15.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      toggleRow(ref),
                      // Summary Cards Row
                      SizedBox(height: 20.h),
                      buildDesktopSummaryCards(context, dashboardState),
                      SizedBox(height: 30.h),

                      // Charts Row 1: Sales Line Chart + Payment Status Chart
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: buildSalesLineChart(context, dashboardState),
                          ),
                          SizedBox(width: 16.spMin),
                          Expanded(
                            flex: 2,
                            child: buildPaymentStatusChart(
                              context,
                              dashboardState,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.spMin),

                      // Charts Row 2: Expense Pie Chart + Customer Bar Chart
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: buildExpensePieChart(
                              context,
                              dashboardState,
                            ),
                          ),
                          SizedBox(width: 16.spMin),
                          Expanded(
                            flex: 2,
                            child: buildCustomerBarChart(
                              context,
                              dashboardState,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Charts Row 3: Comparison Chart + Monthly Breakdown (for yearly view)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: buildComparisonChart(
                              context,
                              dashboardState,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      if (dashboardState.isYearlyView) ...[
                        SizedBox(width: 16.spMin),
                        buildMonthlyBreakdownChart(context, dashboardState),
                      ],
                      SizedBox(height: 20.h),

                      // Top Selling Items Chart
                      buildTopSellingItemsChart(context, dashboardState),
                      SizedBox(height: 20.h),

                      // Profit Loss Chart
                      buildProfitLossChart(context, dashboardState),
                      SizedBox(height: 20.h),

                      // Charts Row 5: Category Profit + Low Stock Alert
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: buildCategoryProfitChart(
                              context,
                              dashboardState,
                            ),
                          ),
                          SizedBox(width: 16.spMin),
                          Expanded(
                            flex: 2,
                            child: buildLowStockAlert(context, dashboardState),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
    );
  }
}
