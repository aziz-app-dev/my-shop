/// A single month of finance data — used both for historical points and for
/// projected (forecast) points in the AI forecasting feature.
class MonthlyPoint {
  final DateTime month; // normalized to the 1st of the month
  final String label; // e.g. "Aug 2026"
  final double sales;
  final double expenses;

  const MonthlyPoint({
    required this.month,
    required this.label,
    required this.sales,
    required this.expenses,
  });

  double get netProfit => sales - expenses;
}

/// Result of a finance forecast: the trailing history, the projected months,
/// a plain-English insight, and whether the numbers came from the AI (Groq)
/// or the local statistical fallback.
class ForecastResult {
  final List<MonthlyPoint> history;
  final List<MonthlyPoint> forecast;
  final String insights;
  final bool usedAi;

  const ForecastResult({
    required this.history,
    required this.forecast,
    required this.insights,
    required this.usedAi,
  });

  /// Projected total sales across the forecast horizon.
  double get projectedSales =>
      forecast.fold(0.0, (sum, p) => sum + p.sales);

  /// Projected total net profit across the forecast horizon.
  double get projectedNetProfit =>
      forecast.fold(0.0, (sum, p) => sum + p.netProfit);
}
