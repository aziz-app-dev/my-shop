/// Holds the shop's currency symbol configured in Settings → General
/// Settings → Currency. A static holder so non-widget code (PDF and
/// thermal-print generators) can read it without a Riverpod scope.
///
/// Defaults to `Rs.` until Settings changes it; the value is part of the
/// synced settings map so every device shows the same currency.
class CurrencyService {
  static String _symbol = 'Rs.';

  /// Current currency symbol, e.g. `Rs.`, `$`, `€`, `₹`, `DA`.
  static String get symbol => _symbol;

  /// Applies a new symbol from Settings. Empty input keeps `Rs.`.
  static void update(String symbol) {
    final trimmed = symbol.trim();
    _symbol = trimmed.isEmpty ? 'Rs.' : trimmed;
  }
}
