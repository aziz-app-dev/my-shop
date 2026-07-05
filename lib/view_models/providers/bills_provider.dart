import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/bills_model.dart';
import '../services/database/database_services.dart'
    hide databaseServiceProvider;
import '../states/bills_states.dart';
import 'sales_provider.dart';
import 'package:riverpod/legacy.dart';

class BillsNotifier extends StateNotifier<BillsState> {
  final DatabaseService _dbService;
  final Ref ref; // Added to access other providers if needed
  final TextEditingController searchController = TextEditingController();

  BillsNotifier(this._dbService, this.ref) : super(BillsState()) {
    fetchBills();
    // Listen to search controller changes
    searchController.addListener(() {
      filterAndSortBills();
    });
  }

  Future<void> fetchBills() async {
    state = state.copyWith(isLoading: true);
    try {
      final bills = await _dbService.getBills();
      state = state.copyWith(
        allBills: bills,
        filteredBills: bills,
        error: null,
        isLoading: false,
      );
      filterAndSortBills();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void filterAndSortBills() {
    List<Bill>? filtered = List.from(state.allBills); // Start with all bills

    // Apply search filter
    final query = searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered =
          filtered.where((bill) {
            return bill.id.toLowerCase().contains(query) ||
                (bill.customerName?.toLowerCase().contains(query) ?? false) ||
                (bill.paymentMethod?.toLowerCase().contains(query) ?? false) ||
                DateFormat(
                  'dd MMM yyyy',
                ).format(bill.dateTime).toLowerCase().contains(query) ||
                DateFormat(
                  'HH:mm',
                ).format(bill.dateTime).toLowerCase().contains(query);
          }).toList();
    }

    // Apply status filter
    if (state.statusFilter != null) {
      filtered =
          filtered.where((bill) => bill.status == state.statusFilter).toList();
    }

    // Apply payment method filter
    if (state.paymentMethodFilter != null) {
      filtered =
          filtered
              .where(
                (bill) =>
                    bill.paymentMethod?.toLowerCase() ==
                    state.paymentMethodFilter?.toLowerCase(),
              )
              .toList();
    }

    // Apply customer filter
    if (state.customerFilter != null) {
      filtered =
          filtered
              .where(
                (bill) =>
                    bill.customerName?.toLowerCase() ==
                    state.customerFilter?.toLowerCase(),
              )
              .toList();
    }

    // Apply date range filter
    if (state.dateRangeFilter != null) {
      filtered =
          filtered.where((bill) {
            return bill.dateTime.isAfter(state.dateRangeFilter!.start) &&
                bill.dateTime.isBefore(state.dateRangeFilter!.end);
          }).toList();
    }

    // Apply total amount range filter
    if (state.totalAmountMin != null) {
      filtered =
          filtered
              .where((bill) => bill.totalAmount >= state.totalAmountMin!)
              .toList();
    }
    if (state.totalAmountMax != null) {
      filtered =
          filtered
              .where((bill) => bill.totalAmount <= state.totalAmountMax!)
              .toList();
    }

    // Apply item count range filter
    if (state.itemCountMin != null) {
      filtered =
          filtered
              .where((bill) => bill.items.length >= state.itemCountMin!)
              .toList();
    }
    if (state.itemCountMax != null) {
      filtered =
          filtered
              .where((bill) => bill.items.length <= state.itemCountMax!)
              .toList();
    }

    // Sort bills
    if (state.sortColumnIndex != null) {
      filtered.sort((a, b) {
        int comparison;
        switch (state.sortColumnIndex) {
          case 1: // Date
            comparison = a.dateTime.compareTo(b.dateTime);
            break;
          default:
            comparison = 0;
        }
        return state.sortAscending ? comparison : -comparison;
      });
    }

    state = state.copyWith(filteredBills: filtered);
  }

  void setStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status);
    filterAndSortBills();
  }

  void setPaymentMethodFilter(String? method) {
    state = state.copyWith(paymentMethodFilter: method);
    filterAndSortBills();
  }

  void setCustomerFilter(String? customer) {
    state = state.copyWith(customerFilter: customer);
    filterAndSortBills();
  }

  void setDateRangeFilter(DateTimeRange? range) {
    state = state.copyWith(dateRangeFilter: range);
    filterAndSortBills();
  }

  void setTotalAmountRange(double? min, double? max) {
    state = state.copyWith(totalAmountMin: min, totalAmountMax: max);
    filterAndSortBills();
  }

  void setItemCountRange(int? min, int? max) {
    state = state.copyWith(itemCountMin: min, itemCountMax: max);
    filterAndSortBills();
  }

  void clearFilters() {
    state = state.copyWith(
      statusFilter: null,
      paymentMethodFilter: null,
      customerFilter: null,
      dateRangeFilter: null,
      totalAmountMin: null,
      totalAmountMax: null,
      itemCountMin: null,
      itemCountMax: null,
      filteredBills:
          state.allBills, // Explicitly reset filteredBills to allBills
    );
    searchController.clear();

    filterAndSortBills(); // Ensure sorting is reapplied if needed
  }

  void clearSearch() {
    searchController.clear();
    state = state.copyWith(filteredBills: state.allBills);
    filterAndSortBills();
  }

  void sortTable(int columnIndex, bool ascending) {
    state = state.copyWith(
      sortColumnIndex: columnIndex,
      sortAscending: ascending,
    );
    filterAndSortBills();
  }

  void toggleBillSelection(String billId, bool? value) {
    final newSelectedBills = Map<String, bool>.from(state.selectedBills);
    if (value != null) {
      newSelectedBills[billId] = value;
    }
    state = state.copyWith(
      selectedBills: newSelectedBills,
      selectAll: newSelectedBills.values.every((v) => v),
    );
  }

  Future<void> deleteSelectedBills() async {
    final selectedBills =
        state.selectedBills.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    for (var billId in selectedBills) {
      await _dbService.deleteBill(billId);
    }

    await fetchBills();
  }

  // Add method to clear all selections
  void clearSelections() {
    state = state.copyWith(selectedBills: {}, isSelectionMode: false);
  }

  // Toggle filter visibility
  void toggleFilterVisibility() {
    state = state.copyWith(isFilterVisible: !state.isFilterVisible);
  }

  void setCurrentPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

final billsProvider = StateNotifierProvider<BillsNotifier, BillsState>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  return BillsNotifier(dbService, ref);
});
