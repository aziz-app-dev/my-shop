import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../models/finance_forecast.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_flushbar.dart';
import '../../../utils/app_sizes.dart';
import '../../../utils/payment_calculator.dart';
import '../../../view_models/providers/dashboard_provider.dart';
import '../../../view_models/providers/forecast_provider.dart';
import 'financial_report_service.dart';

/// Dashboard card for AI finance forecasting: projects the next months of
/// sales/expenses (Groq, with a local fallback) and renders actual-vs-forecast
/// as a chart plus a written insight.
class ForecastCard extends ConsumerWidget {
  const ForecastCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final forecast = ref.watch(forecastProvider);

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
              Icon(TablerIcons.chart_dots, size: 20.spMin, color: AppColors.primary),
              SizedBox(width: 8.spMin),
              Text(
                'AI Finance Forecast',
                style: TextStyle(
                  fontSize: 15.spMin,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (forecast.hasResult) _sourceBadge(forecast.result!.usedAi),
            ],
          ),
          SizedBox(height: 12.spMin),
          if (forecast.isLoading)
            SizedBox(
              height: 200.spMin,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (!forecast.hasResult)
            _buildPrompt(context, ref, isDark)
          else
            _buildResult(context, ref, forecast.result!, isDark),
        ],
      ),
    );
  }

  Widget _sourceBadge(bool usedAi) {
    final color = usedAi ? AppColors.primary : AppColors.grey600;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.spMin, vertical: 3.spMin),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        usedAi ? 'AI (Groq)' : 'Local estimate',
        style: TextStyle(
          fontSize: 10.spMin,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPrompt(BuildContext context, WidgetRef ref, bool isDark) {
    return Column(
      children: [
        SizedBox(height: 8.spMin),
        Icon(TablerIcons.sparkles, size: 40.spMin, color: AppColors.primary),
        SizedBox(height: 12.spMin),
        Text(
          'Project the next 3 months of sales, expenses and profit.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.spMin,
            color: isDark ? AppColors.grey300 : AppColors.grey700,
          ),
        ),
        SizedBox(height: 16.spMin),
        FilledButton.icon(
          onPressed: () => _run(ref),
          icon: Icon(TablerIcons.wand, size: 18.spMin),
          label: const Text('Run forecast'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
        ),
        SizedBox(height: 8.spMin),
      ],
    );
  }

  Widget _buildResult(
    BuildContext context,
    WidgetRef ref,
    ForecastResult result,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220.spMin,
          child: _ForecastChart(result: result, isDark: isDark),
        ),
        SizedBox(height: 12.spMin),
        _legendRow(isDark),
        SizedBox(height: 12.spMin),
        Row(
          children: [
            Expanded(
              child: _projectionTile(
                'Projected sales (3 mo)',
                PaymentCalculator.formatAmount(result.projectedSales),
                AppColors.info,
                isDark,
              ),
            ),
            SizedBox(width: 8.spMin),
            Expanded(
              child: _projectionTile(
                'Projected net profit',
                PaymentCalculator.formatAmount(result.projectedNetProfit),
                result.projectedNetProfit >= 0
                    ? AppColors.success
                    : AppColors.error,
                isDark,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.spMin),
        Container(
          padding: EdgeInsets.all(12.spMin),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(TablerIcons.bulb, size: 16.spMin, color: AppColors.primary),
              SizedBox(width: 8.spMin),
              Expanded(
                child: Text(
                  result.insights,
                  style: TextStyle(
                    fontSize: 12.spMin,
                    height: 1.4,
                    color: isDark ? AppColors.grey300 : AppColors.grey800,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.spMin),
        Wrap(
          spacing: 8.spMin,
          runSpacing: 8.spMin,
          children: [
            OutlinedButton.icon(
              onPressed: () => _run(ref),
              icon: Icon(TablerIcons.refresh, size: 16.spMin),
              label: const Text('Refresh'),
            ),
            FilledButton.icon(
              onPressed: () => _exportWithInsights(context, ref, result),
              icon: Icon(TablerIcons.file_download, size: 16.spMin),
              label: const Text('Export report + AI insights'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendRow(bool isDark) {
    Widget item(Color color, String label, {bool dashed = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16.spMin,
            height: 3.spMin,
            decoration: BoxDecoration(
              color: dashed ? color.withValues(alpha: 0.6) : color,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 4.spMin),
          Text(
            label,
            style: TextStyle(fontSize: 10.spMin, color: AppColors.grey500),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12.spMin,
      runSpacing: 4.spMin,
      children: [
        item(AppColors.info, 'Sales (actual)'),
        item(AppColors.info, 'Sales (forecast)', dashed: true),
        item(AppColors.warning, 'Expenses (actual)'),
        item(AppColors.warning, 'Expenses (forecast)', dashed: true),
      ],
    );
  }

  Widget _projectionTile(String label, String value, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.all(10.spMin),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 15.spMin,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2.spMin),
          Text(
            label,
            style: TextStyle(fontSize: 10.spMin, color: AppColors.grey500),
          ),
        ],
      ),
    );
  }

  void _run(WidgetRef ref) {
    final dashboard = ref.read(dashboardProvider);
    ref.read(forecastProvider.notifier).generate(dashboard);
  }

  Future<void> _exportWithInsights(
    BuildContext context,
    WidgetRef ref,
    ForecastResult result,
  ) async {
    final dashboard = ref.read(dashboardProvider);
    AppFlushbar.success(context, message: 'Generating report with AI insights…');
    try {
      await FinancialReportService.buildSaveOpen(
        ref: ref,
        state: dashboard,
        aiInsights: result.insights,
      );
      if (!context.mounted) return;
      AppFlushbar.success(context, message: 'Report generated');
    } catch (e) {
      if (!context.mounted) return;
      AppFlushbar.error(context, message: 'Failed to generate report: $e');
    }
  }
}

/// The actual-vs-forecast line chart. Actual segments are solid, forecast
/// segments are dashed and start from the last actual point for continuity.
class _ForecastChart extends StatelessWidget {
  final ForecastResult result;
  final bool isDark;

  const _ForecastChart({required this.result, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final history = result.history;
    final forecast = result.forecast;
    final all = [...history, ...forecast];
    if (all.length < 2) {
      return Center(
        child: Text(
          'Need at least 2 months of data to chart a forecast.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.spMin, color: AppColors.grey500),
        ),
      );
    }

    final h = history.length;

    List<FlSpot> actual(double Function(MonthlyPoint) sel) =>
        [for (var i = 0; i < h; i++) FlSpot(i.toDouble(), sel(history[i]))];

    // Forecast segment begins at the last actual point so the dashed line
    // visually continues the solid one.
    List<FlSpot> projected(double Function(MonthlyPoint) sel) => [
          if (h > 0) FlSpot((h - 1).toDouble(), sel(history[h - 1])),
          for (var i = 0; i < forecast.length; i++)
            FlSpot((h + i).toDouble(), sel(forecast[i])),
        ];

    double maxY = 0;
    for (final p in all) {
      if (p.sales > maxY) maxY = p.sales;
      if (p.expenses > maxY) maxY = p.expenses;
    }
    maxY = maxY == 0 ? 1 : maxY * 1.2;

    LineChartBarData bar(
      List<FlSpot> spots,
      Color color, {
      required bool dashed,
    }) {
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.2,
        color: dashed ? color.withValues(alpha: 0.7) : color,
        barWidth: dashed ? 2 : 3,
        isStrokeCapRound: true,
        dashArray: dashed ? [6, 4] : null,
        dotData: FlDotData(
          show: true,
          getDotPainter: (spot, percent, barData, index) =>
              FlDotCirclePainter(
            radius: 2.5,
            color: color,
            strokeWidth: 1,
            strokeColor: Colors.white,
          ),
        ),
        belowBarData: BarAreaData(show: false),
      );
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDark ? AppColors.grey700 : AppColors.grey300,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42.w,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  _short(value),
                  style: TextStyle(fontSize: 9.spMin, color: Colors.grey),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24.h,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= all.length) return const SizedBox();
                // Show the abbreviated month (e.g. "Aug").
                final label = all[i].label.split(' ').first;
                return Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 8.spMin,
                      color: i >= h ? AppColors.primary : Colors.grey,
                      fontWeight:
                          i >= h ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          bar(actual((p) => p.sales), AppColors.info, dashed: false),
          bar(projected((p) => p.sales), AppColors.info, dashed: true),
          bar(actual((p) => p.expenses), AppColors.warning, dashed: false),
          bar(projected((p) => p.expenses), AppColors.warning, dashed: true),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => isDark ? AppColors.grey700 : Colors.white,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt();
              final label = (i >= 0 && i < all.length) ? all[i].label : '';
              return LineTooltipItem(
                '$label\nRs.${s.y.toStringAsFixed(0)}',
                TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 11.spMin,
                  fontWeight: FontWeight.bold,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _short(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}
