import 'package:riverpod/legacy.dart';
import '../../models/brand_model.dart';
import '../../models/items_model.dart';
import '../../view_models/services/database/database_services.dart';

// State class for ShoppingListSearch
class ShoppingListSearchState {
  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final Map<String, int> quantities;
  final Set<String> expandedItems;
  final Map<String, Brand> brandCache; // Cache brands by product ID
  final bool isLoading;
  final String? errorMessage;

  ShoppingListSearchState({
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.quantities = const {},
    this.expandedItems = const {},
    this.brandCache = const {},
    this.isLoading = true,
    this.errorMessage,
  });

  ShoppingListSearchState copyWith({
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    Map<String, int>? quantities,
    Set<String>? expandedItems,
    Map<String, Brand>? brandCache,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ShoppingListSearchState(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      quantities: quantities ?? this.quantities,
      expandedItems: expandedItems ?? this.expandedItems,
      brandCache: brandCache ?? this.brandCache,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// StateNotifier for ShoppingListSearch
class ShoppingListSearchNotifier
    extends StateNotifier<ShoppingListSearchState> {
  final DatabaseService _dbService;
  List<Brand> _allBrands = [];

  ShoppingListSearchNotifier(this._dbService)
    : super(ShoppingListSearchState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final products = await _dbService.getProducts();
      _allBrands = await _dbService.getBrands();

      // Preload brands for all products
      final brandCache = <String, Brand>{};
      for (final product in products) {
        if (product.brand != null && product.brand!.isNotEmpty) {
          final matchingBrand =
              _allBrands.where((b) => b.name == product.brand).firstOrNull;
          if (matchingBrand != null) {
            brandCache[product.id] = matchingBrand;
          }
        }
      }

      state = state.copyWith(
        allProducts: products,
        filteredProducts: products,
        brandCache: brandCache,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error loading products: $e',
      );
    }
  }

  void filterProducts(String query) {
    if (query.isEmpty) {
      state = state.copyWith(filteredProducts: state.allProducts);
    } else {
      final filtered =
          state.allProducts.where((product) {
            return product.name.toLowerCase().contains(query.toLowerCase()) ||
                (product.brand?.toLowerCase().contains(query.toLowerCase()) ??
                    false);
          }).toList();
      state = state.copyWith(filteredProducts: filtered);
    }
  }

  void toggleExpanded(String productId) {
    final newExpandedItems = Set<String>.from(state.expandedItems);
    if (newExpandedItems.contains(productId)) {
      newExpandedItems.remove(productId);
    } else {
      newExpandedItems.add(productId);
    }
    state = state.copyWith(expandedItems: newExpandedItems);
  }

  int getQuantity(String productId) {
    return state.quantities[productId] ?? 1;
  }

  void incrementQuantity(String productId) {
    final newQuantities = Map<String, int>.from(state.quantities);
    newQuantities[productId] = getQuantity(productId) + 1;
    state = state.copyWith(quantities: newQuantities);
  }

  void decrementQuantity(String productId) {
    final currentQty = getQuantity(productId);
    if (currentQty > 1) {
      final newQuantities = Map<String, int>.from(state.quantities);
      newQuantities[productId] = currentQty - 1;
      state = state.copyWith(quantities: newQuantities);
    }
  }

  void resetProduct(String productId) {
    final newQuantities = Map<String, int>.from(state.quantities);
    final newExpandedItems = Set<String>.from(state.expandedItems);
    newQuantities.remove(productId);
    newExpandedItems.remove(productId);
    state = state.copyWith(
      quantities: newQuantities,
      expandedItems: newExpandedItems,
    );
  }

  Brand? getBrandForProduct(String productId) {
    return state.brandCache[productId];
  }
}

// Provider for ShoppingListSearch
final shoppingListSearchProvider = StateNotifierProvider.autoDispose<
  ShoppingListSearchNotifier,
  ShoppingListSearchState
>((ref) => ShoppingListSearchNotifier(DatabaseService()));
