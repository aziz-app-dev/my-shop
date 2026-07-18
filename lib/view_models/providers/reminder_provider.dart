import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../../models/bills_model.dart';
import '../../utils/payment_calculator.dart';
import '../services/database/database_services.dart' hide databaseServiceProvider;
import '../services/notifications/notification_service.dart';
import '../states/reminder_state.dart';
import 'bills_provider.dart';
import 'sales_provider.dart';

/// Drives the payment reminder system.
///
/// Responsibilities:
///  * Load every pending bill that has a due date into [ReminderState].
///  * Run a lightweight in-app ticker (every minute) that fires an OS
///    notification the moment a reminder becomes due while the app is open,
///    recording `reminderNotifiedAt` so it never double-notifies.
///  * Expose actions the reminders screen needs: snooze, mark paid, set/clear
///    a due date.
class ReminderNotifier extends StateNotifier<ReminderState> {
  final DatabaseService _dbService;
  final Ref ref;
  Timer? _ticker;

  ReminderNotifier(this._dbService, this.ref) : super(const ReminderState()) {
    loadReminders();
    // Check once a minute for reminders that have just come due. Desktop apps
    // don't run in the background, so this only fires while the app is open —
    // which is the expected usage for a POS terminal.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      _fireDueNotifications();
    });
  }

  Future<void> loadReminders() async {
    state = state.copyWith(isLoading: true);
    try {
      final bills = await _dbService.getBills();
      final reminders =
          bills.where((b) => b.hasActiveReminder).toList()
            ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      state = state.copyWith(
        reminders: reminders,
        isLoading: false,
        error: null,
      );
      await _fireDueNotifications();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Fires notifications for any reminder that is now due and hasn't been
  /// notified since its current due date.
  Future<void> _fireDueNotifications() async {
    final now = DateTime.now();
    var changed = false;
    for (final bill in state.reminders) {
      final due = bill.dueDate;
      if (due == null) continue;
      final alreadyNotified = bill.reminderNotifiedAt != null &&
          !bill.reminderNotifiedAt!.isBefore(due);
      if (now.isAfter(due) && !alreadyNotified) {
        await NotificationService.instance.showReminder(
          id: bill.id.hashCode & 0x7fffffff,
          title: 'Payment due: ${bill.customerName ?? 'Customer'}',
          body:
              '${PaymentCalculator.formatAmount(bill.pendingAmount)} pending on '
              'bill #${bill.id}',
        );
        final updated = bill.copyWith(reminderNotifiedAt: now);
        await _dbService.saveBill(updated);
        changed = true;
      }
    }
    if (changed) {
      // Reload so the recorded notify-times are reflected without re-firing.
      final bills = await _dbService.getBills();
      final reminders =
          bills.where((b) => b.hasActiveReminder).toList()
            ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
      state = state.copyWith(reminders: reminders);
    }
  }

  /// Pushes a reminder's due date forward by [days] (e.g. snooze 1/3/7 days).
  Future<void> snooze(Bill bill, {int days = 1}) async {
    final base = bill.dueDate ?? DateTime.now();
    final newDue = base.add(Duration(days: days));
    // Clear the notify stamp so the snoozed reminder can fire again.
    final updated =
        bill.copyWith(dueDate: newDue, clearReminderNotifiedAt: true);
    await _dbService.saveBill(updated);
    await _refreshEverywhere();
  }

  /// Sets or updates a bill's payment-due date+time.
  Future<void> setDueDate(Bill bill, DateTime dueDate) async {
    final updated =
        bill.copyWith(dueDate: dueDate, clearReminderNotifiedAt: true);
    await _dbService.saveBill(updated);
    await _refreshEverywhere();
  }

  /// Removes a bill's reminder without touching its payment.
  Future<void> clearReminder(Bill bill) async {
    final updated = bill.copyWith(clearDueDate: true, clearReminderNotifiedAt: true);
    await _dbService.saveBill(updated);
    await _refreshEverywhere();
  }

  /// Marks the outstanding balance as fully collected: sets paid = total and
  /// status = Paid, which removes it from the reminder list.
  Future<void> markPaid(Bill bill) async {
    final updated = bill.copyWith(
      paidAmount: bill.totalAfterDiscount,
      status: 'Paid',
      clearDueDate: true,
      clearReminderNotifiedAt: true,
    );
    await _dbService.saveBill(updated);
    await _refreshEverywhere();
  }

  /// Refresh reminders and keep the bills list in sync so both screens agree.
  Future<void> _refreshEverywhere() async {
    await loadReminders();
    try {
      await ref.read(billsProvider.notifier).fetchBills();
    } catch (e) {
      debugPrint('Reminder refresh: bills provider not ready ($e)');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  return ReminderNotifier(dbService, ref);
});
