import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/local_purchase_model.dart';
import '../services/database/database_services.dart';
import '../states/local_purchase_states.dart';
import 'package:riverpod/legacy.dart';

class LocalPurchaseNotifier extends StateNotifier<LocalPurchaseState> {
  final DatabaseService _dbService;
  final TextEditingController searchController = TextEditingController();

  /// True once dummy demo data has been checked/seeded, so the check only
  /// runs on the first fetch after app start instead of every fetch.
  bool _seedCompleted = false;

  LocalPurchaseNotifier(this._dbService) : super(LocalPurchaseState()) {
    fetchAgreements();
    searchController.addListener(() {
      filterAgreements();
    });
  }

  /// Seeds a handful of demo purchase agreements when the list is completely
  /// empty (fresh install), so the purchases screen shows real-looking
  /// content. Runs once per notifier lifetime; silently skipped afterwards.
  Future<void> _seedDummyDataIfEmpty() async {
    if (_seedCompleted) return;
    _seedCompleted = true;

    try {
      final existing = await _dbService.getLocalPurchases();
      if (existing.isNotEmpty) return;

      final now = DateTime.now();
      final demo = <LocalPurchaseAgreement>[
        LocalPurchaseAgreement(
          id: 'DEMO-LP-001',
          dateTime: now.subtract(const Duration(days: 1)),
          sellerName: 'Imran Chaudhry',
          sellerPhone: '0300-4456678',
          sellerIdCard: '35202-8876541-9',
          sellerAddress: 'Block C, Johar Town, Lahore',
          paymentType: 'Cash',
          items: [
            LocalPurchaseItem(
              id: 'demo-1-1',
              name: 'HP ProBook 450 G9 — i5 12th Gen, 16GB, 512GB SSD',
              quantity: 2,
              unitPrice: 95000,
            ),
            LocalPurchaseItem(
              id: 'demo-1-2',
              name: 'Chromebook 14" — 4GB, 64GB (as-is)',
              quantity: 3,
              unitPrice: 22000,
            ),
          ],
          totalAmount: 2 * 95000 + 3 * 22000,
          notes: 'Purchased with original boxes and chargers included.',
        ),
        LocalPurchaseAgreement(
          id: 'DEMO-LP-002',
          dateTime: now.subtract(const Duration(days: 2, hours: 3)),
          sellerName: 'Bilal Traders',
          sellerPhone: '0321-7788990',
          sellerAddress: 'Hafeez Center, Gulberg III, Lahore',
          paymentType: 'Bank Transfer',
          items: [
            LocalPurchaseItem(
              id: 'demo-2-1',
              name: 'Dell Latitude 5420 — i5, 8GB, 256GB',
              quantity: 5,
              unitPrice: 78000,
            ),
          ],
          totalAmount: 5 * 78000,
          notes: 'Bulk lot from an office liquidation.',
        ),
        LocalPurchaseAgreement(
          id: 'DEMO-LP-003',
          dateTime: now.subtract(const Duration(days: 5)),
          sellerName: 'Ayesha Khan',
          sellerPhone: '0333-9871122',
          paymentType: 'Cheque',
          items: [
            LocalPurchaseItem(
              id: 'demo-3-1',
              name: 'iPhone 12 — 64GB, 89% battery health',
              quantity: 1,
              unitPrice: 112000,
            ),
            LocalPurchaseItem(
              id: 'demo-3-2',
              name: 'iPhone 12 Pro Max — 128GB, 91% battery health',
              quantity: 1,
              unitPrice: 215000,
            ),
          ],
          totalAmount: 112000 + 215000,
        ),
        LocalPurchaseAgreement(
          id: 'DEMO-LP-004',
          dateTime: now.subtract(const Duration(days: 9, hours: 6)),
          sellerName: 'Sheikh Mobiles',
          sellerPhone: '0345-3334445',
          sellerIdCard: '42201-1122334-5',
          sellerAddress: 'Main Boulevard, Gulshan-e-Ravi, Lahore',
          paymentType: 'UPI / Digital',
          items: [
            LocalPurchaseItem(
              id: 'demo-4-1',
              name: 'Samsung Galaxy A54 — 8GB, 128GB',
              quantity: 4,
              unitPrice: 54500,
            ),
            LocalPurchaseItem(
              id: 'demo-4-2',
              name: 'Mobile accessory bundle — covers, tempered glass',
              quantity: 20,
              unitPrice: 350,
            ),
          ],
          totalAmount: 4 * 54500 + 20 * 350,
          notes: 'Cheque cleared on time. Repeat seller.',
        ),
        LocalPurchaseAgreement(
          id: 'DEMO-LP-005',
          dateTime: now.subtract(const Duration(days: 14)),
          sellerName: 'Waqas Computers',
          sellerPhone: '0311-2200110',
          paymentType: 'Cash',
          items: [
            LocalPurchaseItem(
              id: 'demo-5-1',
              name: 'Gaming PC — RTX 3060, i7, 16GB (used)',
              quantity: 1,
              unitPrice: 168000,
            ),
            LocalPurchaseItem(
              id: 'demo-5-2',
              name: '24" IPS monitor — 75Hz (minor scratch)',
              quantity: 2,
              unitPrice: 19500,
            ),
          ],
          totalAmount: 168000 + 2 * 19500,
        ),
      ];

      for (final agreement in demo) {
        await _dbService.saveLocalPurchase(agreement);
      }
    } catch (_) {
      // Seeding is cosmetic-only — never let it break the real fetch.
    }
  }

  Future<void> fetchAgreements() async {
    state = state.copyWith(isLoading: true);
    try {
      // First fetch after app start: if the list is totally empty, drop in
      // demo agreements so the UI/UX is visible on a fresh install.
      await _seedDummyDataIfEmpty();

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
    final selected =
        state.selectedAgreements.entries
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
    state = state.copyWith(selectedAgreements: {}, isSelectionMode: false);
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
