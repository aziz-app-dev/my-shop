import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_services.dart';
import 'sync_queue.dart';

@immutable
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int queuedOps;
  final String message;

  const SyncStatus({
    required this.isOnline,
    required this.isSyncing,
    required this.queuedOps,
    required this.message,
  });

  SyncStatus copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? queuedOps,
    String? message,
  }) {
    return SyncStatus(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      queuedOps: queuedOps ?? this.queuedOps,
      message: message ?? this.message,
    );
  }
}

/// Offline-first sync:
/// - Local Hive is source of truth offline.
/// - Writes enqueue into `sync_queue` and are flushed when online.
/// - Realtime updates from Supabase are applied to Hive.
///
/// Assumption: you have Supabase tables named:
/// `products`, `customers`, `bills`, `brands`, `categories`, `expenses`
/// with columns compatible with the app's `toMap()` keys (stored as JSON for nested fields where needed).
class SupabaseSyncService {
  final SupabaseClient _supabase;
  final HiveService _hive;
  final SyncQueue _queue;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  RealtimeChannel? _productsChannel;
  RealtimeChannel? _customersChannel;
  RealtimeChannel? _billsChannel;

  final ValueNotifier<SyncStatus> status = ValueNotifier(
    const SyncStatus(
      isOnline: false,
      isSyncing: false,
      queuedOps: 0,
      message: 'Sync not started',
    ),
  );

  bool _started = false;
  bool _flushing = false;

  SupabaseSyncService({
    SupabaseClient? supabase,
    required HiveService hive,
    required SyncQueue queue,
    Connectivity? connectivity,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _hive = hive,
       _queue = queue,
       _connectivity = connectivity ?? Connectivity();

  Future<void> start() async {
    if (_started) return;
    _started = true;

    status.value = status.value.copyWith(
      queuedOps: _queue.length,
      message: 'Starting sync...',
    );

    _connSub = _connectivity.onConnectivityChanged.listen(
      (results) async {
        final online = results.any((r) => r != ConnectivityResult.none);
        status.value = status.value.copyWith(
          isOnline: online,
          queuedOps: _queue.length,
          message: online ? 'Online' : 'Offline',
        );

        if (online) {
          await flushQueue();
        }
      },
      // The connectivity_plus Windows implementation can throw a
      // PlatformException (NetworkManager::StartListen) when it fails to
      // activate the change stream. Swallow it instead of crashing — we still
      // fall back to the initial checkConnectivity() reading below.
      onError: (Object e, StackTrace st) {
        debugPrint('Connectivity stream error (ignored): $e');
      },
      cancelOnError: false,
    );

    // Initial online detection. checkConnectivity() can also throw on Windows;
    // assume online so sync isn't permanently disabled by a platform hiccup.
    bool online;
    try {
      final initial = await _connectivity.checkConnectivity();
      online = initial.any((r) => r != ConnectivityResult.none);
    } catch (e) {
      debugPrint('checkConnectivity failed (assuming online): $e');
      online = true;
    }
    status.value = status.value.copyWith(
      isOnline: online,
      queuedOps: _queue.length,
      message: online ? 'Online' : 'Offline',
    );

    _startRealtime();

    if (online) {
      await flushQueue();
    }
  }

  void _startRealtime() {
    // Products
    _productsChannel ??=
        _supabase
            .channel('realtime:products')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'products',
              callback: (payload) {
                _applyRealtimeChange(table: 'products', payload: payload);
              },
            )
            .subscribe();

    // Customers
    _customersChannel ??=
        _supabase
            .channel('realtime:customers')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'customers',
              callback: (payload) {
                _applyRealtimeChange(table: 'customers', payload: payload);
              },
            )
            .subscribe();

    // Bills
    _billsChannel ??=
        _supabase
            .channel('realtime:bills')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'bills',
              callback: (payload) {
                _applyRealtimeChange(table: 'bills', payload: payload);
              },
            )
            .subscribe();
  }

  Future<void> _applyRealtimeChange({
    required String table,
    required PostgresChangePayload payload,
  }) async {
    try {
      final eventType = payload.eventType;
      if (eventType == PostgresChangeEvent.delete) {
        final oldRow = payload.oldRecord;
        final id = (oldRow['id'] ?? '').toString();
        if (id.isEmpty) return;
        await _hive.applyRemoteDelete(table: table, id: id);
        return;
      }

      final row = payload.newRecord;
      final id = (row['id'] ?? '').toString();
      if (id.isEmpty) return;
      await _hive.applyRemoteUpsert(table: table, record: row);
    } catch (e) {
      debugPrint('Realtime apply error ($table): $e');
    }
  }

  Future<void> flushQueue() async {
    if (_flushing) return;
    _flushing = true;
    status.value = status.value.copyWith(isSyncing: true, message: 'Syncing...');

    try {
      final ops = _queue.peekAllSorted();
      for (final op in ops) {
        try {
          if (op.type == SyncOpType.upsert) {
            await _supabase.from(op.table).upsert(op.payload);
          } else {
            final id = (op.payload['id'] ?? '').toString();
            if (id.isNotEmpty) {
              await _supabase.from(op.table).delete().eq('id', id);
            }
          }
          await _queue.remove(op.id);
          status.value = status.value.copyWith(queuedOps: _queue.length);
        } catch (e) {
          // Stop on first failure (likely offline / permission / schema issue)
          debugPrint('Queue flush failed on op ${op.id}: $e');
          status.value = status.value.copyWith(
            message: 'Sync paused: ${e.toString()}',
          );
          break;
        }
      }
    } finally {
      _flushing = false;
      status.value = status.value.copyWith(
        isSyncing: false,
        queuedOps: _queue.length,
        message:
            status.value.isOnline
                ? (_queue.length == 0 ? 'Synced' : 'Pending sync')
                : 'Offline',
      );
    }
  }

  Future<void> dispose() async {
    await _connSub?.cancel();
    _connSub = null;

    if (_productsChannel != null) {
      await _supabase.removeChannel(_productsChannel!);
      _productsChannel = null;
    }
    if (_customersChannel != null) {
      await _supabase.removeChannel(_customersChannel!);
      _customersChannel = null;
    }
    if (_billsChannel != null) {
      await _supabase.removeChannel(_billsChannel!);
      _billsChannel = null;
    }

    status.dispose();
  }
}

