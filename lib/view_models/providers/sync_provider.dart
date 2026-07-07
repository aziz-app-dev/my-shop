import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/database/database_services.dart';
import '../services/sync/firestore_sync_service.dart';
import '../services/sync/sync_queue.dart';

/// Starts background sync once and keeps it alive.
final syncControllerProvider = FutureProvider<SyncController>((ref) async {
  final hive = ref.watch(hiveServiceProvider);
  final queue = await SyncQueue.open();
  final sync = FirestoreSyncService(hive: hive, queue: queue);
  await sync.start();

  final controller = SyncController(sync: sync);
  ref.onDispose(controller.dispose);
  return controller;
});

class SyncController {
  final FirestoreSyncService _sync;

  SyncController({required FirestoreSyncService sync}) : _sync = sync;

  ValueNotifier<SyncStatus> get statusNotifier => _sync.status;

  Future<void> flushNow() async {
    await _sync.flushQueue();
  }

  Future<void> dispose() async {
    await _sync.dispose();
  }
}

