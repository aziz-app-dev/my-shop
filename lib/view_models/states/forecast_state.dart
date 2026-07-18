import '../../models/finance_forecast.dart';

/// UI state for the AI finance forecast card on the dashboard.
class ForecastState {
  final bool isLoading;
  final ForecastResult? result;
  final String? error;

  const ForecastState({
    this.isLoading = false,
    this.result,
    this.error,
  });

  bool get hasResult => result != null;

  ForecastState copyWith({
    bool? isLoading,
    ForecastResult? result,
    String? error,
    bool clearError = false,
  }) {
    return ForecastState(
      isLoading: isLoading ?? this.isLoading,
      result: result ?? this.result,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
