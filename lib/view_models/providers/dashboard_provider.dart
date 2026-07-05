// ignore_for_file: unnecessary_cast

import 'package:riverpod/legacy.dart';

import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';
import '../../models/expense_model.dart';
import '../../models/items_model.dart';
import '../../models/shopping_list_model.dart';
import '../services/database/database_services.dart';
import '../states/dashboard_state.dart';

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DatabaseService _dbService;

  DashboardNotifier(this._dbService) : super(const DashboardState());

  /// Load all data for dashboard analytics
  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Load all data in parallel
      final results = await Future.wait([
        _dbService.getBills(),
        _dbService.getCustomers(),
        _dbService.getExpenses(),
        _loadAllShoppingItems(),
        _dbService.getProducts(),
      ]);

      state = state.copyWith(
        isLoading: false,
        bills: (results[0] as List).cast<Bill>(),
        customers: (results[1] as List).cast<Customer>(),
        expenses: (results[2] as List).cast<Expense>(),
        shoppingItems: (results[3] as List).cast<ShoppingListItem>(),
        products: (results[4] as List).cast<Product>(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load all shopping items from all lists
  Future<List<dynamic>> _loadAllShoppingItems() async {
    try {
      final lists = await _dbService.getShoppingLists();
      final allItems = <dynamic>[];

      for (final list in lists) {
        final items = await _dbService.getShoppingListItems(list.id);
        allItems.addAll(items);
      }

      return allItems;
    } catch (e) {
      return [];
    }
  }

  /// Set selected month for analytics
  void setSelectedMonth(DateTime month) {
    state = state.copyWith(selectedMonth: DateTime(month.year, month.month, 1));
  }

  /// Go to previous month
  void goToPreviousMonth() {
    final current = state.selectedMonth;
    setSelectedMonth(DateTime(current.year, current.month - 1, 1));
  }

  /// Go to next month
  void goToNextMonth() {
    final current = state.selectedMonth;
    setSelectedMonth(DateTime(current.year, current.month + 1, 1));
  }

  /// Toggle between monthly and yearly view
  void toggleYearlyView() {
    state = state.copyWith(isYearlyView: !state.isYearlyView);
  }

  /// Set yearly view
  void setYearlyView(bool isYearly) {
    state = state.copyWith(isYearlyView: isYearly);
  }

  /// Set selected year (for yearly view)
  void setSelectedYear(int year) {
    state = state.copyWith(
      selectedMonth: DateTime(year, state.selectedMonth.month, 1),
    );
  }

  /// Go to previous year
  void goToPreviousYear() {
    final current = state.selectedMonth;
    setSelectedYear(current.year - 1);
  }

  /// Go to next year
  void goToNextYear() {
    final current = state.selectedMonth;
    setSelectedYear(current.year + 1);
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadAllData();
  }
}

// Provider
final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
      final dbService = ref.watch(databaseServiceProvider);
      return DashboardNotifier(dbService);
    });
