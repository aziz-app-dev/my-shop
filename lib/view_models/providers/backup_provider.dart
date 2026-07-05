import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup/backup_service.dart';
import '../services/database/database_services.dart';
import 'package:riverpod/legacy.dart';

/// Backup state class
class BackupState {
  final bool isBackingUp;
  final bool isRestoring;
  final double progress;
  final String statusMessage;
  final String? error;
  final DateTime? lastBackupTime;
  final Map<String, int>? lastBackupItemsCount;

  const BackupState({
    this.isBackingUp = false,
    this.isRestoring = false,
    this.progress = 0.0,
    this.statusMessage = '',
    this.error,
    this.lastBackupTime,
    this.lastBackupItemsCount,
  });

  BackupState copyWith({
    bool? isBackingUp,
    bool? isRestoring,
    double? progress,
    String? statusMessage,
    String? error,
    DateTime? lastBackupTime,
    Map<String, int>? lastBackupItemsCount,
  }) {
    return BackupState(
      isBackingUp: isBackingUp ?? this.isBackingUp,
      isRestoring: isRestoring ?? this.isRestoring,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      error: error,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      lastBackupItemsCount: lastBackupItemsCount ?? this.lastBackupItemsCount,
    );
  }
}

/// Backup state notifier
class BackupNotifier extends StateNotifier<BackupState> {
  final BackupService _backupService;

  BackupNotifier(this._backupService) : super(const BackupState()) {
    // Load last backup info on initialization
    _loadLastBackupInfo();
  }

  Future<void> _loadLastBackupInfo() async {
    try {
      final info = await _backupService.getLastBackupInfo();
      if (info != null) {
        final timestamp = info['updatedAt'];
        DateTime? lastTime;

        if (timestamp is DateTime) {
          lastTime = timestamp;
        }

        final itemsCount = info['itemsCount'] as Map<String, dynamic>?;
        Map<String, int>? counts;

        if (itemsCount != null) {
          counts = itemsCount.map((key, value) => MapEntry(key, value as int));
        }

        state = state.copyWith(
          lastBackupTime: lastTime,
          lastBackupItemsCount: counts,
        );
      }
    } catch (e, stack) {
      debugPrint('❌ Error loading last backup info: $e');
      debugPrint("$stack");
    }
  }

  /// Start backup process
  Future<bool> startBackup() async {
    if (state.isBackingUp || state.isRestoring) {
      return false;
    }

    state = state.copyWith(
      isBackingUp: true,
      progress: 0.0,
      statusMessage: 'Preparing backup...',
      error: null,
    );

    final success = await _backupService.createBackup(
      onProgress: (progress, status) {
        if (progress < 0) {
          debugPrint('❌ Backup error: $status');

          state = state.copyWith(
            isBackingUp: false,
            progress: 0.0,
            statusMessage: '',
            error: status,
          );
        } else {
          state = state.copyWith(progress: progress, statusMessage: status);
          debugPrint('❌ Backup error: $status');
        }
      },
    );

    if (success) {
      await _loadLastBackupInfo();
      state = state.copyWith(
        isBackingUp: false,
        progress: 1.0,
        statusMessage: 'Backup completed!',
      );
    }

    return success;
  }

  /// Start restore process
  Future<bool> startRestore() async {
    if (state.isBackingUp || state.isRestoring) {
      return false;
    }

    state = state.copyWith(
      isRestoring: true,
      progress: 0.0,
      statusMessage: 'Preparing restore...',
      error: null,
    );

    final success = await _backupService.restoreBackup(
      onProgress: (progress, status) {
        if (progress < 0) {
          debugPrint('❌ Restore error: $status');

          state = state.copyWith(
            isRestoring: false,
            progress: 0.0,
            statusMessage: '',
            error: status,
          );
        } else {
          state = state.copyWith(progress: progress, statusMessage: status);
          debugPrint('🔄 Restore progress: $status');
        }
      },
    );

    if (success) {
      state = state.copyWith(
        isRestoring: false,
        progress: 1.0,
        statusMessage: 'Restore completed!',
      );
    }

    return success;
  }

  /// Reset backup state
  void reset() {
    state = BackupState(
      lastBackupTime: state.lastBackupTime,
      lastBackupItemsCount: state.lastBackupItemsCount,
    );
  }

  /// Check if backup exists
  Future<bool> hasBackup() async {
    return await _backupService.hasBackup();
  }
}

/// Backup service provider
final backupServiceProvider = Provider<BackupService>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return BackupService(hiveService);
});

/// Backup state provider
final backupProvider = StateNotifierProvider<BackupNotifier, BackupState>((
  ref,
) {
  final backupService = ref.watch(backupServiceProvider);
  return BackupNotifier(backupService);
});
