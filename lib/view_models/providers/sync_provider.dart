import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bills_provider.dart';
import 'customer_prvider.dart';
import 'dashboard_provider.dart';
import 'expense_provider.dart';
import 'home_page_provider.dart';
import 'local_purchase_provider.dart';
import 'product_view.dart';
import 'repair_provider.dart';
import '../services/database/database_services.dart';
import '../services/sync/firestore_sync_service.dart';
import '../services/sync/sync_queue.dart';

/// Starts background sync once and keeps it alive.
final syncControllerProvider = FutureProvider<SyncController>((ref) async {
  final hive = ref.watch(hiveServiceProvider);
  final queue = await SyncQueue.open();
  final sync = FirestoreSyncService(hive: hive, queue: queue);
  await sync.start();

  final controller = SyncController(sync: sync, hive: hive, ref: ref);
  ref.onDispose(controller.dispose);
  return controller;
});

/// Reloads the matching UI providers when remote (other-device) changes
/// land in local Hive. Bursts are debounced so a snapshot batch triggers
/// one refresh per table instead of one per document.
class SyncController {
  final FirestoreSyncService _sync;
  final HiveService _hive;
  final Ref _ref;

  StreamSubscription<String>? _remoteSub;
  Timer? _refreshDebounce;
  final Set<String> _pendingTables = {};

  SyncController({
    required FirestoreSyncService sync,
    required HiveService hive,
    required Ref ref,
  }) : _sync = sync,
       _hive = hive,
       _ref = ref {
    _remoteSub = _hive.remoteDataChanges.listen(_onRemoteChange);
  }

  void _onRemoteChange(String table) {
    _pendingTables.add(table);
    // Collapse bursts: wait a moment for the rest of the snapshot batch.
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 500), _refreshUi);
  }

  /// Reloads every provider whose backing table changed, so open screens
  /// show other devices' changes immediately.
  void _refreshUi() {
    if (_pendingTables.isEmpty) return;
    final tables = Set<String>.from(_pendingTables);
    _pendingTables.clear();

    for (final table in tables) {
      try {
        switch (table) {
          case 'products':
            _ref.read(productsNotifierProvider.notifier).refreshProducts();
            continue;
          case 'customers':
            _ref.read(customersProvider.notifier).fetchData();
            continue;
          case 'bills':
            _ref.read(billsProvider.notifier).fetchBills();
            _ref.read(dashboardProvider.notifier).loadAllData();
            continue;
          case 'expenses':
            _ref.read(expenseProvider.notifier).loadData();
            continue;
          case 'repairs':
            _ref.read(repairProvider.notifier).loadRepairs();
            continue;
          case 'localPurchases':
            _ref.read(localPurchaseProvider.notifier).fetchAgreements();
            continue;
        }
      } catch (e) {
        // A provider that isn't currently built (autoDispose) throws on
        // read(.notifier) — safe to ignore, it re-loads when opened.
        debugPrint('Remote-change refresh skipped for "$table": $e');
      }
    }
    // Home screen stock/summary depends on products, bills and customers.
    if (tables.any(
      (t) => t == 'products' || t == 'bills' || t == 'customers',
    )) {
      try {
        _ref.read(homePageProvider.notifier).loadHomeData();
      } catch (e) {
        debugPrint('Home refresh skipped: $e');
      }
    }
  }

  ValueNotifier<SyncStatus> get statusNotifier => _sync.status;

  Future<void> flushNow() async {
    await _sync.flushQueue();
  }

  Future<void> dispose() async {
    await _remoteSub?.cancel();
    _remoteSub = null;
    _refreshDebounce?.cancel();
    await _sync.dispose();
  }
}
