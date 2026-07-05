import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';
import '../../models/items_model.dart';
import '../services/database/database_services.dart';
import '../states/edit_bill_state.dart';
import 'package:riverpod/legacy.dart';

class EditBillNotifier extends StateNotifier<EditBillState> {
  final DatabaseService _databaseService;
  final Bill bill;

  EditBillNotifier(this._databaseService, this.bill)
    : super(
        EditBillState(
          updatedQuantities: Map.from(bill.quantities),
          updatedItems: List.from(bill.items),
        ),
      );

  // Load customers
  Future<void> loadCustomers() async {
    try {
      state = state.copyWith(isLoading: true);
      final customers = await _databaseService.getCustomers();
      state = state.copyWith(
        fullCustomers: customers,
        filteredCustomers: customers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // Filter customers based on search query
  void filterCustomers(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        filteredCustomers: state.fullCustomers,
        showSuggestions: false,
      );
    } else {
      final filtered =
          state.fullCustomers
              .where(
                (customer) =>
                    customer.name.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
      state = state.copyWith(
        filteredCustomers: filtered,
        showSuggestions: true,
      );
    }
  }

  // Hide suggestions
  void hideSuggestions() {
    state = state.copyWith(showSuggestions: false);
  }

  // Update quantity for an item
  void updateQuantity(String itemId, int newQuantity) {
    final updatedQuantities = Map<String, int>.from(state.updatedQuantities);
    if (newQuantity > 0) {
      updatedQuantities[itemId] = newQuantity;
    } else {
      updatedQuantities.remove(itemId);
    }
    state = state.copyWith(updatedQuantities: updatedQuantities);
  }

  // Increment quantity
  void incrementQuantity(String itemId) {
    final currentQty = state.updatedQuantities[itemId] ?? 1;
    updateQuantity(itemId, currentQty + 1);
  }

  // Decrement quantity
  void decrementQuantity(String itemId) {
    final currentQty = state.updatedQuantities[itemId] ?? 1;
    if (currentQty > 1) {
      updateQuantity(itemId, currentQty - 1);
    }
  }

  // Remove item from bill
  void removeItem(int index) {
    final updatedItems = List<Product>.from(state.updatedItems);
    final updatedQuantities = Map<String, int>.from(state.updatedQuantities);

    if (index >= 0 && index < updatedItems.length) {
      final item = updatedItems[index];
      updatedItems.removeAt(index);
      updatedQuantities.remove(item.id);

      state = state.copyWith(
        updatedItems: updatedItems,
        updatedQuantities: updatedQuantities,
      );
    }
  }

  // Get customer by name
  Customer? getCustomerByName(String name) {
    try {
      return state.fullCustomers.firstWhere((c) => c.name == name);
    } catch (e) {
      return null;
    }
  }
}

final editBillProvider =
    StateNotifierProvider.family<EditBillNotifier, EditBillState, Bill>(
      (ref, bill) => EditBillNotifier(ref.read(databaseServiceProvider), bill),
    );
