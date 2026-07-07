import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum SyncOpType { upsert, delete }

@immutable
class SyncOp {
  final String id;
  final String table;
  final SyncOpType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const SyncOp({
    required this.id,
    required this.table,
    required this.type,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'table': table,
      'type': type.name,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static SyncOp fromMap(Map<String, dynamic> map) {
    final typeStr = (map['type'] ?? 'upsert').toString();
    final type = SyncOpType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => SyncOpType.upsert,
    );
    return SyncOp(
      id: (map['id'] ?? '').toString(),
      table: (map['table'] ?? '').toString(),
      type: type,
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? const {}),
      createdAt:
          DateTime.tryParse((map['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

/// Simple persistent FIFO queue stored in Hive.
class SyncQueue {
  static const String boxName = 'sync_queue';

  final Box<Map> _box;

  SyncQueue(this._box);

  static Future<SyncQueue> open() async {
    final box = await Hive.openBox<Map>(boxName);
    return SyncQueue(box);
  }

  /// Whether the underlying Hive box is still usable. After a hot restart,
  /// logout, or directory change the box may be closed while a lingering
  /// connectivity/stream callback still holds a reference to this queue —
  /// touching a closed box throws `HiveError: Box has already been closed`.
  bool get isOpen => _box.isOpen;

  Future<void> enqueue(SyncOp op) async {
    if (!_box.isOpen) return;
    await _box.put(op.id, op.toMap());
  }

  List<SyncOp> peekAllSorted() {
    if (!_box.isOpen) return const [];
    final ops =
        _box.values
            .map((e) => SyncOp.fromMap(Map<String, dynamic>.from(e)))
            .toList();
    ops.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return ops;
  }

  Future<void> remove(String id) async {
    if (!_box.isOpen) return;
    await _box.delete(id);
  }

  int get length => _box.isOpen ? _box.length : 0;
}

