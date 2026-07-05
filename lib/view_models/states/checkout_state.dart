import '../../models/coustomer_model.dart';

class CheckoutState {
  final List<Customer> fullCustomers;
  final List<Customer> filteredCustomers;
  final bool showSuggestions;
  final bool isWalkIn;
  final bool isTestBill;

  const CheckoutState({
    this.fullCustomers = const [],
    this.filteredCustomers = const [],
    this.showSuggestions = false,
    this.isWalkIn = false,
    this.isTestBill = false,
  });

  CheckoutState copyWith({
    List<Customer>? fullCustomers,
    List<Customer>? filteredCustomers,
    bool? showSuggestions,
    bool? isWalkIn,
    bool? isTestBill,
  }) {
    return CheckoutState(
      fullCustomers: fullCustomers ?? this.fullCustomers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      isWalkIn: isWalkIn ?? this.isWalkIn,
      isTestBill: isTestBill ?? this.isTestBill,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CheckoutState &&
        other.fullCustomers == fullCustomers &&
        other.filteredCustomers == filteredCustomers &&
        other.showSuggestions == showSuggestions &&
        other.isWalkIn == isWalkIn &&
        other.isTestBill == isTestBill;
  }

  @override
  int get hashCode => Object.hash(
    fullCustomers,
    filteredCustomers,
    showSuggestions,
    isWalkIn,
    isTestBill,
  );
}
