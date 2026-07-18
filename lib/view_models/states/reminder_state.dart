import '../../models/bills_model.dart';

/// Immutable state for the payment reminder system. Holds every pending bill
/// that has a payment-due date set, already sorted by soonest due first.
class ReminderState {
  final List<Bill> reminders;
  final bool isLoading;
  final String? error;

  const ReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.error,
  });

  /// Bills whose due date has already passed and are still owed.
  List<Bill> get overdue =>
      reminders.where((b) => (b.daysUntilDue ?? 0) < 0).toList();

  /// Bills due today (same calendar day).
  List<Bill> get dueToday =>
      reminders.where((b) => b.daysUntilDue == 0).toList();

  /// Bills due on a future day.
  List<Bill> get upcoming =>
      reminders.where((b) => (b.daysUntilDue ?? 0) > 0).toList();

  /// Count of reminders needing attention now (overdue + due today) — used for
  /// the navigation/dashboard badge.
  int get actionableCount => overdue.length + dueToday.length;

  double get totalOverdueAmount =>
      overdue.fold(0.0, (sum, b) => sum + b.pendingAmount);

  double get totalReminderAmount =>
      reminders.fold(0.0, (sum, b) => sum + b.pendingAmount);

  ReminderState copyWith({
    List<Bill>? reminders,
    bool? isLoading,
    String? error,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
