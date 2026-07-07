import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../database/database_services.dart';
import '../firebase/firebase_service.dart';
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

/// Offline-first sync backed by Cloud Firestore.
///
/// - Local Hive is the source of truth. Writes enqueue into `sync_queue` and
///   are flushed to Firestore when online.
/// - Existing cloud rows are pulled once ([pullAll]) so a fresh install sees
///   the shop's data.
/// - Realtime Firestore listeners apply remote changes back into Hive.
///
/// All data lives under `users/{uid}/{collection}/{id}` where `collection` is
/// one of products/customers/bills/brands/categories/expenses. Nothing syncs
/// while signed out (there is no uid to scope to).
class FirestoreSyncService {
  final FirebaseService _fb;
  final HiveService _hive;
  final SyncQueue _queue;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  final List<StreamSubscription> _realtimeSubs = [];

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
  bool _disposed = false;

  FirestoreSyncService({
    FirebaseService? firebase,
    required HiveService hive,
    required SyncQueue queue,
    Connectivity? connectivity,
  }) : _fb = firebase ?? FirebaseService.instance,
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
        if (_disposed || !_queue.isOpen) return;

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
      onError: (Object e, StackTrace st) {
        debugPrint('Connectivity stream error (ignored): $e');
      },
      cancelOnError: false,
    );

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
      // Push queued local writes up, then pull existing cloud rows down.
      await flushQueue();
      await pullAll();
    }
  }

  void _startRealtime() {
    if (!_fb.isSignedIn) return; // Nothing to listen to while signed out.
    for (final name in FirebaseService.dataCollections) {
      final sub = _fb.collection(name).snapshots().listen(
        (snapshot) => _applySnapshot(name, snapshot),
        onError: (e) => debugPrint('Realtime listen error ($name): $e'),
      );
      _realtimeSubs.add(sub);
    }
  }

  Future<void> _applySnapshot(
    String table,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (_disposed) return;
    for (final change in snapshot.docChanges) {
      try {
        final id = change.doc.id;
        if (change.type == DocumentChangeType.removed) {
          await _hive.applyRemoteDelete(table: table, id: id);
        } else {
          final data = change.doc.data();
          if (data == null) continue;
          await _hive.applyRemoteUpsert(
            table: table,
            record: Map<String, dynamic>.from(data),
          );
        }
      } catch (e) {
        debugPrint('Realtime apply error ($table): $e');
      }
    }
  }

  /// One-shot bulk fetch of existing cloud rows into local Hive.
  Future<void> pullAll() async {
    if (_disposed || !_fb.isSignedIn) return;
    for (final table in FirebaseService.dataCollections) {
      try {
        final snapshot = await _fb.collection(table).get();
        for (final doc in snapshot.docs) {
          if (_disposed) return;
          await _hive.applyRemoteUpsert(
            table: table,
            record: Map<String, dynamic>.from(doc.data()),
          );
        }
      } catch (e) {
        debugPrint('Initial pull failed for "$table": $e');
      }
    }
  }

  Future<void> flushQueue() async {
    if (_flushing || _disposed || !_queue.isOpen) return;
    if (!_fb.isSignedIn) return; // Can't scope writes without a uid.
    _flushing = true;
    status.value = status.value.copyWith(isSyncing: true, message: 'Syncing...');

    try {
      final ops = _queue.peekAllSorted();
      for (final op in ops) {
        try {
          final id = (op.payload['id'] ?? op.id).toString();
          final col = _fb.collection(op.table);
          if (op.type == SyncOpType.upsert) {
            await col.doc(id).set(
              Map<String, dynamic>.from(op.payload),
              SetOptions(merge: true),
            );
          } else {
            if (id.isNotEmpty) {
              await col.doc(id).delete();
            }
          }
          await _queue.remove(op.id);
          status.value = status.value.copyWith(queuedOps: _queue.length);
        } catch (e) {
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
    _disposed = true;
    await _connSub?.cancel();
    _connSub = null;
    for (final sub in _realtimeSubs) {
      await sub.cancel();
    }
    _realtimeSubs.clear();
    status.dispose();
  }
}
