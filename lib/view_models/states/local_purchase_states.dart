import 'package:flutter/foundation.dart';
import '../../models/local_purchase_model.dart';

class LocalPurchaseState {
  final List<LocalPurchaseAgreement> allAgreements;
  final List<LocalPurchaseAgreement> filteredAgreements;
  final bool isLoading;
  final String? error;
  final Map<String, bool> selectedAgreements;
  final bool isSelectionMode;
  final String? searchQuery;

  LocalPurchaseState({
    this.allAgreements = const [],
    this.filteredAgreements = const [],
    this.isLoading = true,
    this.error,
    Map<String, bool>? selectedAgreements,
    this.isSelectionMode = false,
    this.searchQuery,
  }) : selectedAgreements = selectedAgreements ?? {};

  bool get hasSelections =>
      selectedAgreements.values.any((selected) => selected);

  int get selectedCount =>
      selectedAgreements.values.where((selected) => selected).length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocalPurchaseState &&
        listEquals(other.allAgreements, allAgreements) &&
        listEquals(other.filteredAgreements, filteredAgreements) &&
        other.isLoading == isLoading &&
        other.error == error &&
        mapEquals(other.selectedAgreements, selectedAgreements) &&
        other.isSelectionMode == isSelectionMode &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode {
    return allAgreements.hashCode ^
        filteredAgreements.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        selectedAgreements.hashCode ^
        isSelectionMode.hashCode ^
        searchQuery.hashCode;
  }

  LocalPurchaseState copyWith({
    List<LocalPurchaseAgreement>? allAgreements,
    List<LocalPurchaseAgreement>? filteredAgreements,
    bool? isLoading,
    String? error,
    Map<String, bool>? selectedAgreements,
    bool? isSelectionMode,
    String? searchQuery,
    bool clearError = false,
    bool clearSearchQuery = false,
  }) {
    return LocalPurchaseState(
      allAgreements: allAgreements ?? this.allAgreements,
      filteredAgreements: filteredAgreements ?? this.filteredAgreements,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedAgreements: selectedAgreements ?? this.selectedAgreements,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
    );
  }
}
