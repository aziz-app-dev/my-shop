/// Utility class for consistent payment calculations across the app
class PaymentCalculator {
  PaymentCalculator._();

  /// Calculates the total amount after applying discount
  static double calculateTotalAfterDiscount({
    required double totalAmount,
    required double discount,
  }) {
    return totalAmount - discount;
  }

  /// Calculates the pending/remaining amount to be paid
  static double calculatePendingAmount({
    required double totalAmount,
    required double discount,
    required double paidAmount,
  }) {
    final totalAfterDiscount = calculateTotalAfterDiscount(
      totalAmount: totalAmount,
      discount: discount,
    );
    final remaining = totalAfterDiscount - paidAmount;
    return remaining > 0 ? remaining : 0.0;
  }

  /// Determines if a bill is fully paid
  /// Uses a small tolerance (0.01) for floating-point comparison
  static bool isFullyPaid({
    required double totalAmount,
    required double discount,
    required double paidAmount,
  }) {
    final pending = calculatePendingAmount(
      totalAmount: totalAmount,
      discount: discount,
      paidAmount: paidAmount,
    );
    return pending <= 0.01;
  }

  /// Determines if this is a partial payment
  static bool isPartialPayment({
    required double totalAmount,
    required double discount,
    required double paidAmount,
  }) {
    final pending = calculatePendingAmount(
      totalAmount: totalAmount,
      discount: discount,
      paidAmount: paidAmount,
    );
    return paidAmount > 0 && pending > 0.01;
  }

  /// Calculates payment status string: 'Paid' or 'Pending'
  static String calculatePaymentStatus({
    required double totalAmount,
    required double discount,
    required double paidAmount,
  }) {
    return isFullyPaid(
      totalAmount: totalAmount,
      discount: discount,
      paidAmount: paidAmount,
    )
        ? 'Paid'
        : 'Pending';
  }

  /// Calculates payment completion percentage (0-100)
  static double calculatePaymentPercentage({
    required double totalAmount,
    required double discount,
    required double paidAmount,
  }) {
    final totalAfterDiscount = calculateTotalAfterDiscount(
      totalAmount: totalAmount,
      discount: discount,
    );
    if (totalAfterDiscount <= 0) return 100.0;
    return (paidAmount / totalAfterDiscount * 100).clamp(0.0, 100.0);
  }

  /// Validates that discount doesn't exceed total amount
  static bool isDiscountValid({
    required double totalAmount,
    required double discount,
  }) {
    return discount >= 0 && discount <= totalAmount;
  }

  /// Validates that paid amount doesn't exceed total after discount
  static bool isPaidAmountValid({
    required double totalAmount,
    required double discount,
    required double paidAmount,
  }) {
    if (paidAmount < 0) return false;
    final totalAfterDiscount = calculateTotalAfterDiscount(
      totalAmount: totalAmount,
      discount: discount,
    );
    return paidAmount <= totalAfterDiscount;
  }

  /// Validates all payment fields together
  static PaymentValidationResult validatePayment({
    required double totalAmount,
    required double discount,
    required double paidAmount,
  }) {
    if (!isDiscountValid(totalAmount: totalAmount, discount: discount)) {
      return PaymentValidationResult(
        isValid: false,
        errorMessage: 'Discount cannot exceed total amount',
      );
    }

    if (!isPaidAmountValid(
      totalAmount: totalAmount,
      discount: discount,
      paidAmount: paidAmount,
    )) {
      return PaymentValidationResult(
        isValid: false,
        errorMessage: 'Paid amount cannot exceed total after discount',
      );
    }

    return PaymentValidationResult(isValid: true);
  }

  /// Formats amount to display string with currency symbol
  static String formatAmount(double amount, {String symbol = 'Rs.'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Formats amount for display without decimal places
  static String formatAmountSimple(double amount, {String symbol = 'Rs.'}) {
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}

/// Result of payment validation
class PaymentValidationResult {
  final bool isValid;
  final String? errorMessage;

  PaymentValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}
