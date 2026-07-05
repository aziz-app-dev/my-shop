import '../../models/items_model.dart';

class BrandProductsState {
  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  BrandProductsState({
    this.allProducts = const [],
    this.filteredProducts = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  BrandProductsState copyWith({
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return BrandProductsState(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
