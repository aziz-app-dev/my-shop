import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/local_purchase_model.dart';
import '../services/database/database_services.dart';
import '../states/local_purchase_states.dart';
import 'package:riverpod/legacy.dart';

class LocalPurchaseNotifier extends StateNotifier<LocalPurchaseState> {
  final DatabaseService _dbService;
  final TextEditingController searchController = TextEditingController();

  LocalPurchaseNotifier(this._dbService) : super(LocalPurchaseState()) {
    fetchAgreements();
    searchController.addListener(() {
      filterAgreements();
    });
  }

  Future<void> fetchAgreements() async {
    state = state.copyWith(isLoading: true);
    try {
      final agreements = await _dbService.getLocalPurchases();
      state = state.copyWith(
        allAgreements: agreements,
        filteredAgreements: agreements,
        error: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void filterAgreements() {
    final query = searchController.text.toLowerCase();
    List<LocalPurchaseAgreement> filtered = List.from(state.allAgreements);

    if (query.isNotEmpty) {
      filtered =
          filtered.where((agreement) {
            return agreement.sellerName.toLowerCase().contains(query) ||
                (agreement.sellerPhone?.toLowerCase().contains(query) ??
                    false) ||
                (agreement.sellerIdCard?.toLowerCase().contains(query) ??
                    false) ||
                agreement.id.toLowerCase().contains(query) ||
                DateFormat(
                  'dd MMM yyyy',
                ).format(agreement.dateTime).toLowerCase().contains(query);
          }).toList();
    }

    state = state.copyWith(
      filteredAgreements: filtered,
      searchQuery: query.isNotEmpty ? query : null,
    );
  }

  Future<void> saveAgreement(LocalPurchaseAgreement agreement) async {
    await _dbService.saveLocalPurchase(agreement);
    await fetchAgreements();
  }

  Future<void> deleteAgreement(String id) async {
    await _dbService.deleteLocalPurchase(id);
    await fetchAgreements();
  }

  Future<void> deleteSelected() async {
    final selected = state.selectedAgreements.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    for (final id in selected) {
      await _dbService.deleteLocalPurchase(id);
    }

    await fetchAgreements();
    clearSelections();
  }

  void toggleSelection(String id, bool? value) {
    final newSelected = Map<String, bool>.from(state.selectedAgreements);
    if (value != null) {
      newSelected[id] = value;
    }
    state = state.copyWith(
      selectedAgreements: newSelected,
      isSelectionMode: newSelected.isNotEmpty,
    );
  }

  void clearSelections() {
    state = state.copyWith(
      selectedAgreements: {},
      isSelectionMode: false,
    );
  }

  void setSelectionMode(bool enabled) {
    state = state.copyWith(isSelectionMode: enabled);
    if (!enabled) {
      clearSelections();
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

final localPurchaseProvider =
    StateNotifierProvider<LocalPurchaseNotifier, LocalPurchaseState>((ref) {
  final dbService = ref.read(databaseServiceProvider);
  return LocalPurchaseNotifier(dbService);
});
