import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';

class CustomersState {
  final List<Customer> allCustomers;
  final List<Customer> filteredCustomers;
  final List<Bill> allBills;
  final Map<String, int> pendingBillCounts;
  final Map<String, int> completedBillCounts;
  final Map<String, double> pendingAmounts;
  final String? error;
  final int? sortColumnIndex;
  final bool sortAscending;
  final int currentPage;
  final int recordsPerPage;
  final bool isSelectionMode;
  final Map<String, bool> selectedCustomers;
  final bool isLoading;

  CustomersState({
    this.allCustomers = const [],
    this.filteredCustomers = const [],
    this.allBills = const [],
    this.pendingBillCounts = const {},
    this.completedBillCounts = const {},
    this.pendingAmounts = const {},
    this.error,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.currentPage = 1,
    this.recordsPerPage = 10,
    this.isSelectionMode = false,
    this.selectedCustomers = const {},
    this.isLoading = true,
  });

  CustomersState copyWith({
    List<Customer>? allCustomers,
    List<Customer>? filteredCustomers,
    List<Bill>? allBills,
    Map<String, int>? pendingBillCounts,
    Map<String, int>? completedBillCounts,
    Map<String, double>? pendingAmounts,
    String? error,
    int? sortColumnIndex,
    bool? sortAscending,
    int? currentPage,
    int? recordsPerPage,
    bool? isSelectionMode,
    Map<String, bool>? selectedCustomers,
    bool? isLoading,
  }) {
    return CustomersState(
      allCustomers: allCustomers ?? this.allCustomers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      allBills: allBills ?? this.allBills,
      pendingBillCounts: pendingBillCounts ?? this.pendingBillCounts,
      completedBillCounts: completedBillCounts ?? this.completedBillCounts,
      pendingAmounts: pendingAmounts ?? this.pendingAmounts,
      error: error,
      sortColumnIndex: sortColumnIndex ?? this.sortColumnIndex,
      sortAscending: sortAscending ?? this.sortAscending,
      currentPage: currentPage ?? this.currentPage,
      recordsPerPage: recordsPerPage ?? this.recordsPerPage,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedCustomers: selectedCustomers ?? this.selectedCustomers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
