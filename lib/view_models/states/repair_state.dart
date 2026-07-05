import '../../models/repair_model.dart';

class RepairState {
  final List<Repair> repairs; // All repair jobs
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final bool showCompleted; // When false, hide completed jobs from the list

  RepairState({
    this.repairs = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.showCompleted = true,
  });

  List<Repair> get filteredRepairs {
    var list = repairs;

    if (!showCompleted) {
      list = list.where((r) => !r.isCompleted).toList();
    }

    if (searchQuery.isEmpty) return list;

    final q = searchQuery.toLowerCase();
    return list.where((r) {
      return r.clientName.toLowerCase().contains(q) ||
          r.clientPhone.toLowerCase().contains(q) ||
          r.deviceType.toLowerCase().contains(q) ||
          r.brand.toLowerCase().contains(q) ||
          r.model.toLowerCase().contains(q) ||
          r.serialNumber.toLowerCase().contains(q) ||
          r.problem.toLowerCase().contains(q);
    }).toList();
  }

  int get totalCount => repairs.length;
  int get pendingCount => repairs.where((r) => !r.isCompleted).length;
  int get completedCount => repairs.where((r) => r.isCompleted).length;
  double get totalPendingBalance => repairs
      .where((r) => !r.isCompleted)
      .fold(0.0, (sum, r) => sum + r.balanceDue);

  RepairState copyWith({
    List<Repair>? repairs,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool? showCompleted,
  }) {
    return RepairState(
      repairs: repairs ?? this.repairs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      showCompleted: showCompleted ?? this.showCompleted,
    );
  }
}
