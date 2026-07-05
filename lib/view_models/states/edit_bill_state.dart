import '../../models/coustomer_model.dart';
import '../../models/items_model.dart';

class EditBillState {
  final List<Customer> fullCustomers;
  final List<Customer> filteredCustomers;
  final bool showSuggestions;
  final Map<String, int> updatedQuantities;
  final List<Product> updatedItems;
  final bool isLoading;

  EditBillState({
    this.fullCustomers = const [],
    this.filteredCustomers = const [],
    this.showSuggestions = false,
    this.updatedQuantities = const {},
    this.updatedItems = const [],
    this.isLoading = false,
  });

  EditBillState copyWith({
    List<Customer>? fullCustomers,
    List<Customer>? filteredCustomers,
    bool? showSuggestions,
    Map<String, int>? updatedQuantities,
    List<Product>? updatedItems,
    bool? isLoading,
  }) {
    return EditBillState(
      fullCustomers: fullCustomers ?? this.fullCustomers,
      filteredCustomers: filteredCustomers ?? this.filteredCustomers,
      showSuggestions: showSuggestions ?? this.showSuggestions,
      updatedQuantities: updatedQuantities ?? this.updatedQuantities,
      updatedItems: updatedItems ?? this.updatedItems,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
