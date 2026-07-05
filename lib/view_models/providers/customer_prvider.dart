// Providers for customers
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/coustomer_model.dart';
import '../states/customer_states.dart';
import 'add_prduct_provider.dart';
import 'package:riverpod/legacy.dart';

final customersProvider =
    StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
      return CustomersNotifier(ref);
    });

class CustomersNotifier extends StateNotifier<CustomersState> {
  final Ref ref;

  CustomersNotifier(this.ref) : super(CustomersState()) {
    fetchData();
  }

  Future<void> fetchData() async {
    state = state.copyWith(isLoading: true);
    try {
      final customers = await ref.read(databaseServiceProvider).getCustomers();
      final bills = await ref.read(databaseServiceProvider).getBills();
      final Map<String, int> pendingCounts = {};
      final Map<String, int> completedCounts = {};
      final Map<String, double> pendingAmounts = {};

      for (var bill in bills) {
        final cid = bill.customerId;
        if (cid != null) {
          pendingCounts.putIfAbsent(cid, () => 0);
          completedCounts.putIfAbsent(cid, () => 0);
          pendingAmounts.putIfAbsent(cid, () => 0.0);

          if (bill.status == 'Pending') {
            pendingCounts[cid] = (pendingCounts[cid] ?? 0) + 1;
            final finalAmount = bill.totalAmount - bill.discount;
            pendingAmounts[cid] =
                (pendingAmounts[cid] ?? 0.0) + (finalAmount - bill.paidAmount);
          } else {
            completedCounts[cid] = (completedCounts[cid] ?? 0) + 1;
          }
        }
      }

      state = state.copyWith(
        allCustomers: customers,
        filteredCustomers: customers,
        allBills: bills,
        pendingBillCounts: pendingCounts,
        completedBillCounts: completedCounts,
        pendingAmounts: pendingAmounts,
        error: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void sortCustomers(int columnIndex, bool ascending) {
    state = state.copyWith(
      sortColumnIndex: columnIndex,
      sortAscending: ascending,
    );
    List<Customer> sorted = List.from(state.filteredCustomers);
    sorted.sort((a, b) {
      int comparison = 0;
      switch (columnIndex) {
        case 0: // Name
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 1: // Phone Number
          comparison = a.phoneNumber.compareTo(b.phoneNumber);
          break;
        case 2: // Address
          comparison = a.address.toLowerCase().compareTo(
            b.address.toLowerCase(),
          );
          break;
        case 3: // Visits
          comparison = a.visitCount.compareTo(b.visitCount);
          break;
        case 4: // Bill Status (Pending Amount or Completed)
          final pa = state.pendingAmounts[a.id] ?? 0.0;
          final pb = state.pendingAmounts[b.id] ?? 0.0;
          final ca = state.completedBillCounts[a.id] ?? 0;
          final cb = state.completedBillCounts[b.id] ?? 0;
          if (pa > 0 && pb > 0) {
            comparison = pa.compareTo(pb);
          } else if (pa > 0) {
            comparison = 1;
          } else if (pb > 0) {
            comparison = -1;
          } else {
            comparison = ca.compareTo(cb);
          }
          break;
      }
      return ascending ? comparison : -comparison;
    });
    state = state.copyWith(filteredCustomers: sorted);
  }

  void toggleCustomerSelection(String customerId, bool? selected) {
    final newSelectedCustomers = Map<String, bool>.from(
      state.selectedCustomers,
    );
    if (selected != null) {
      newSelectedCustomers[customerId] = selected;
    } else {
      newSelectedCustomers.remove(customerId);
    }
    final isSelectionMode = newSelectedCustomers.values.any((v) => v);
    state = state.copyWith(
      selectedCustomers: newSelectedCustomers,
      isSelectionMode: isSelectionMode,
    );
  }

  void setPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  void searchCustomers(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        filteredCustomers: state.allCustomers,
        currentPage: 1, // Reset to first page when clearing search
      );
    } else {
      final filtered =
          state.allCustomers.where((customer) {
            final queryLower = query.toLowerCase();
            return customer.name.toLowerCase().contains(queryLower) ||
                customer.phoneNumber.toLowerCase().contains(queryLower) ||
                customer.address.toLowerCase().contains(queryLower);
          }).toList();
      state = state.copyWith(
        filteredCustomers: filtered,
        currentPage: 1, // Reset to first page when filtering
      );
    }
  }

  Future<void> refresh() async {
    await fetchData();
  }
}
