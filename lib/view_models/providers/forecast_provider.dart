import 'package:intl/intl.dart';
import 'package:riverpod/legacy.dart';

import '../../models/bills_model.dart';
import '../../models/expense_model.dart';
import '../../models/finance_forecast.dart';
import '../services/ai/groq_forecast_service.dart';
import '../states/dashboard_state.dart';
import '../states/forecast_state.dart';

class ForecastNotifier extends StateNotifier<ForecastState> {
  ForecastNotifier() : super(const ForecastState());

  /// Number of trailing months of history fed into the forecast.
  static const int historyMonths = 6;

  /// Number of months projected forward.
  static const int forecastMonths = 3;

  /// Runs a forecast off the dashboard's raw bills/expenses. Uses Groq when a
  /// key is configured, otherwise a local trend (handled by the service).
  Future<void> generate(DashboardState dashboard) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final history = buildHistory(
        dashboard.bills,
        dashboard.expenses,
        historyMonths,
      );
      final result = await GroqForecastService.forecast(
        history,
        monthsAhead: forecastMonths,
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Aggregates the trailing [months] months of sales (bill totals after
  /// discount) and expenses into monthly buckets, oldest first.
  static List<MonthlyPoint> buildHistory(
    List<Bill> bills,
    List<Expense> expenses,
    int months,
  ) {
    final now = DateTime.now();
    final points = <MonthlyPoint>[];
    for (var i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final sales = bills
          .where((b) =>
              b.dateTime.year == m.year && b.dateTime.month == m.month)
          .fold<double>(0.0, (s, b) => s + b.totalAfterDiscount);
      final exp = expenses
          .where((e) => e.date.year == m.year && e.date.month == m.month)
          .fold<double>(0.0, (s, e) => s + e.amount);
      points.add(MonthlyPoint(
        month: m,
        label: DateFormat('MMM yyyy').format(m),
        sales: sales,
        expenses: exp,
      ));
    }
    return points;
  }
}

final forecastProvider =
    StateNotifierProvider<ForecastNotifier, ForecastState>(
  (ref) => ForecastNotifier(),
);
