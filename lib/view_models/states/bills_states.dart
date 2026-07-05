import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../models/bills_model.dart';

class BillsState {
  final List<Bill> allBills;
  final List<Bill> filteredBills;
  final bool sortAscending;
  final int? sortColumnIndex;
  final String? statusFilter;
  final String? paymentMethodFilter;
  final String? customerFilter;
  final double? totalAmountMin;
  final double? totalAmountMax;
  final int? itemCountMin;
  final int? itemCountMax;
  final String? error;
  final DateTimeRange? dateRangeFilter;
  final Map<String, bool> selectedBills;
  final bool selectAll;
  final int currentPage;
  final int recordsPerPage;
  final bool isSelectionMode;
  final bool isFilterVisible;
  final bool isLoading;

  BillsState({
    this.allBills = const [],
    this.filteredBills = const [],
    this.sortAscending = true,
    this.sortColumnIndex = 1,
    this.statusFilter,
    this.paymentMethodFilter,
    this.customerFilter,
    this.totalAmountMin,
    this.totalAmountMax,
    this.itemCountMin,
    this.itemCountMax,
    this.error,
    this.dateRangeFilter,
    Map<String, bool>? selectedBills,
    this.selectAll = false,
    this.currentPage = 1,
    this.recordsPerPage = 20,
    this.isSelectionMode = false,
    this.isFilterVisible = false,
    this.isLoading = true,
  }) : selectedBills = selectedBills ?? {};

  // Helper getter to check if we're in selection mode based on selected bills
  bool get hasSelections => selectedBills.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BillsState &&
        listEquals(other.allBills, allBills) &&
        listEquals(other.filteredBills, filteredBills) &&
        other.sortAscending == sortAscending &&
        other.sortColumnIndex == sortColumnIndex &&
        other.statusFilter == statusFilter &&
        other.paymentMethodFilter == paymentMethodFilter &&
        other.customerFilter == customerFilter &&
        other.totalAmountMin == totalAmountMin &&
        other.totalAmountMax == totalAmountMax &&
        other.itemCountMin == itemCountMin &&
        other.itemCountMax == itemCountMax &&
        other.error == error &&
        other.dateRangeFilter == dateRangeFilter &&
        mapEquals(other.selectedBills, selectedBills) &&
        other.selectAll == selectAll &&
        other.currentPage == currentPage &&
        other.recordsPerPage == recordsPerPage &&
        other.isSelectionMode == isSelectionMode &&
        other.isFilterVisible == isFilterVisible &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return allBills.hashCode ^
        filteredBills.hashCode ^
        sortAscending.hashCode ^
        sortColumnIndex.hashCode ^
        statusFilter.hashCode ^
        paymentMethodFilter.hashCode ^
        customerFilter.hashCode ^
        totalAmountMin.hashCode ^
        totalAmountMax.hashCode ^
        itemCountMin.hashCode ^
        itemCountMax.hashCode ^
        error.hashCode ^
        dateRangeFilter.hashCode ^
        selectedBills.hashCode ^
        selectAll.hashCode ^
        currentPage.hashCode ^
        recordsPerPage.hashCode ^
        isSelectionMode.hashCode ^
        isFilterVisible.hashCode ^
        isLoading.hashCode;
  }

  BillsState copyWith({
    List<Bill>? allBills,
    List<Bill>? filteredBills,
    bool? sortAscending,
    int? sortColumnIndex,
    String? statusFilter,
    String? paymentMethodFilter,
    String? customerFilter,
    double? totalAmountMin,
    double? totalAmountMax,
    int? itemCountMin,
    int? itemCountMax,
    String? error,
    DateTimeRange? dateRangeFilter,
    Map<String, bool>? selectedBills,
    bool? selectAll,
    int? currentPage,
    int? recordsPerPage,
    bool? isSelectionMode,
    bool? isFilterVisible,
    bool? isLoading,
  }) {
    return BillsState(
      allBills: allBills ?? this.allBills,
      filteredBills: filteredBills ?? this.filteredBills,
      sortAscending: sortAscending ?? this.sortAscending,
      sortColumnIndex: sortColumnIndex ?? this.sortColumnIndex,
      statusFilter: statusFilter ?? this.statusFilter,
      paymentMethodFilter: paymentMethodFilter ?? this.paymentMethodFilter,
      customerFilter: customerFilter ?? this.customerFilter,
      totalAmountMin: totalAmountMin ?? this.totalAmountMin,
      totalAmountMax: totalAmountMax ?? this.totalAmountMax,
      itemCountMin: itemCountMin ?? this.itemCountMin,
      itemCountMax: itemCountMax ?? this.itemCountMax,
      error: error ?? this.error,
      dateRangeFilter: dateRangeFilter ?? this.dateRangeFilter,
      selectedBills: selectedBills ?? this.selectedBills,
      selectAll: selectAll ?? this.selectAll,
      currentPage: currentPage ?? this.currentPage,
      recordsPerPage: recordsPerPage ?? this.recordsPerPage,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      isFilterVisible: isFilterVisible ?? this.isFilterVisible,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
