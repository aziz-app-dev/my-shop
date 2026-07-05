import 'package:riverpod/legacy.dart';

import '../../models/repair_model.dart';
import '../services/database/database_services.dart';
import '../states/repair_state.dart';

final repairProvider = StateNotifierProvider<RepairNotifier, RepairState>((ref) {
  return RepairNotifier();
});

class RepairNotifier extends StateNotifier<RepairState> {
  RepairNotifier() : super(RepairState()) {
    loadRepairs();
  }

  final DatabaseService _dbService = DatabaseService();

  Future<void> loadRepairs() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repairs = await _dbService.getRepairs();
      state = state.copyWith(repairs: repairs, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Create a brand new repair job.
  Future<void> addRepair(Repair repair) async {
    try {
      await _dbService.addRepair(repair);
      await loadRepairs();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Update an existing repair job.
  Future<void> updateRepair(Repair repair) async {
    try {
      final updated = repair.copyWith(updatedAt: DateTime.now());
      await _dbService.updateRepair(updated);
      await loadRepairs();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteRepair(String id) async {
    try {
      await _dbService.deleteRepair(id);
      await loadRepairs();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Toggle the completed (repaired / delivered) flag.
  Future<void> toggleCompleted(String id) async {
    try {
      final repair = state.repairs.firstWhere((r) => r.id == id);
      final updated = repair.copyWith(
        isCompleted: !repair.isCompleted,
        updatedAt: DateTime.now(),
      );
      await _dbService.updateRepair(updated);
      await loadRepairs();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleShowCompleted() {
    state = state.copyWith(showCompleted: !state.showCompleted);
  }
}
