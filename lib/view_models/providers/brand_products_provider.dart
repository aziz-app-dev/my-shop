import '../../models/brand_model.dart';
import '../services/database/database_services.dart';
import '../states/brand_products_state.dart';
import 'package:riverpod/legacy.dart';

class BrandProductsNotifier extends StateNotifier<BrandProductsState> {
  final DatabaseService _dbService;
  final Brand brand;

  BrandProductsNotifier(this._dbService, this.brand)
    : super(BrandProductsState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final allProducts = await _dbService.getProducts();
      final brandProducts =
          allProducts.where((p) => p.brand == brand.name).toList();

      state = state.copyWith(
        allProducts: brandProducts,
        filteredProducts: brandProducts,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void searchProducts(String query) {
    state = state.copyWith(searchQuery: query);

    if (query.isEmpty) {
      state = state.copyWith(filteredProducts: state.allProducts);
    } else {
      final filtered =
          state.allProducts.where((product) {
            final nameLower = product.name.toLowerCase();
            final searchLower = query.toLowerCase();
            return nameLower.contains(searchLower);
          }).toList();

      state = state.copyWith(filteredProducts: filtered);
    }
  }

  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      filteredProducts: state.allProducts,
    );
  }

  Future<void> refreshProducts() async {
    await loadProducts();
  }
}

// Provider factory that takes a Brand parameter
final brandProductsProvider = StateNotifierProvider.family<
  BrandProductsNotifier,
  BrandProductsState,
  Brand
>((ref, brand) {
  return BrandProductsNotifier(DatabaseService(), brand);
});
