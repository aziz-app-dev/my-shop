import '../states/checkout_state.dart';
import '../../models/coustomer_model.dart';
import 'package:riverpod/legacy.dart';

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  CheckoutNotifier() : super(const CheckoutState());

  // Load all customers
  void loadCustomers(List<Customer> customers) {
    state = state.copyWith(
      fullCustomers: customers,
      filteredCustomers: customers,
    );
  }

  // Filter customers by search query
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
        showSuggestions: !state.isWalkIn,
      );
    }
  }

  // Hide suggestions
  void hideSuggestions() {
    state = state.copyWith(showSuggestions: false);
  }

  // Toggle walk-in mode
  void toggleWalkIn(bool value) {
    state = state.copyWith(
      isWalkIn: value,
      isTestBill: false,
      showSuggestions: false,
    );
  }

  // Toggle test bill mode
  void toggleTestBill(bool value) {
    state = state.copyWith(
      isTestBill: value,
      isWalkIn: false,
      showSuggestions: false,
    );
  }

  // Reset to customer mode (both walk-in and test bill off)
  void setCustomerMode() {
    state = state.copyWith(
      isWalkIn: false,
      isTestBill: false,
      showSuggestions: false,
    );
  }
}

// Provider
final checkoutProvider =
    StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(
      (ref) => CheckoutNotifier(),
    );
