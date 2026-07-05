import 'package:riverpod/legacy.dart';
import '../../models/expense_model.dart';
import '../services/database/database_services.dart';

// State class for expenses
class ExpenseState {
  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final bool isLoading;
  final String? error;
  final String? selectedCategoryFilter;
  final DateTime? startDateFilter;
  final DateTime? endDateFilter;
  final DateTime selectedMonth; // Track selected month for pie chart

  ExpenseState({
    this.expenses = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategoryFilter,
    this.startDateFilter,
    this.endDateFilter,
    DateTime? selectedMonth,
  }) : selectedMonth = selectedMonth ?? DateTime.now();

  ExpenseState copyWith({
    List<Expense>? expenses,
    List<ExpenseCategory>? categories,
    bool? isLoading,
    String? error,
    String? selectedCategoryFilter,
    DateTime? startDateFilter,
    DateTime? endDateFilter,
    DateTime? selectedMonth,
    bool clearCategoryFilter = false,
    bool clearDateFilter = false,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategoryFilter:
          clearCategoryFilter
              ? null
              : (selectedCategoryFilter ?? this.selectedCategoryFilter),
      startDateFilter:
          clearDateFilter ? null : (startDateFilter ?? this.startDateFilter),
      endDateFilter:
          clearDateFilter ? null : (endDateFilter ?? this.endDateFilter),
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  // Get expenses for the selected month
  List<Expense> get selectedMonthExpenses {
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

    return expenses.where((e) {
      return e.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          e.date.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  // Alias for backward compatibility
  List<Expense> get currentMonthExpenses => selectedMonthExpenses;

  // Get total for selected month
  double get currentMonthTotal {
    return selectedMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  // Get expenses grouped by category for pie chart
  Map<String, double> get expensesByCategory {
    final Map<String, double> result = {};
    for (final expense in selectedMonthExpenses) {
      final categoryName = expense.categoryName ?? 'Other';
      result[categoryName] = (result[categoryName] ?? 0) + expense.amount;
    }
    return result;
  }

  // Get filtered expenses
  List<Expense> get filteredExpenses {
    var result = expenses;

    if (selectedCategoryFilter != null) {
      result =
          result.where((e) => e.categoryId == selectedCategoryFilter).toList();
    }

    if (startDateFilter != null && endDateFilter != null) {
      result =
          result.where((e) {
            return e.date.isAfter(
                  startDateFilter!.subtract(const Duration(days: 1)),
                ) &&
                e.date.isBefore(endDateFilter!.add(const Duration(days: 1)));
          }).toList();
    }

    return result;
  }
}

// Notifier for expense state
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final HiveService _hiveService;

  ExpenseNotifier(this._hiveService) : super(ExpenseState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final expenses = await _hiveService.getExpenses();
      final categories = await _hiveService.getExpenseCategories();
      state = state.copyWith(
        expenses: expenses,
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      // Get category name for display
      final category = state.categories.firstWhere(
        (c) => c.id == expense.categoryId,
        orElse: () => ExpenseCategory(name: 'Other'),
      );
      final expenseWithCategory = expense.copyWith(categoryName: category.name);

      await _hiveService.addExpense(expenseWithCategory);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final category = state.categories.firstWhere(
        (c) => c.id == expense.categoryId,
        orElse: () => ExpenseCategory(name: 'Other'),
      );
      final expenseWithCategory = expense.copyWith(categoryName: category.name);

      await _hiveService.updateExpense(expenseWithCategory);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _hiveService.deleteExpense(id);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addCategory(ExpenseCategory category) async {
    try {
      await _hiveService.addExpenseCategory(category);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _hiveService.deleteExpenseCategory(id);
      await loadData();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setCategoryFilter(String? categoryId) {
    state = state.copyWith(
      selectedCategoryFilter: categoryId,
      clearCategoryFilter: categoryId == null,
    );
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDateFilter: start,
      endDateFilter: end,
      clearDateFilter: start == null && end == null,
    );
  }

  void clearFilters() {
    state = state.copyWith(clearCategoryFilter: true, clearDateFilter: true);
  }

  void setSelectedMonth(DateTime month) {
    state = state.copyWith(selectedMonth: DateTime(month.year, month.month, 1));
  }

  void goToPreviousMonth() {
    final current = state.selectedMonth;
    setSelectedMonth(DateTime(current.year, current.month - 1, 1));
  }

  void goToNextMonth() {
    final current = state.selectedMonth;
    setSelectedMonth(DateTime(current.year, current.month + 1, 1));
  }
}

// Provider
final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((
  ref,
) {
  final hiveService = ref.watch(hiveServiceProvider);
  return ExpenseNotifier(hiveService);
});
