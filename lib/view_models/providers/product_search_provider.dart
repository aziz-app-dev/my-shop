import '../states/product_search_state.dart';
import 'package:riverpod/legacy.dart';

class ProductSearchNotifier extends StateNotifier<ProductSearchState> {
  ProductSearchNotifier() : super(const ProductSearchState());

  // Update search query
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // Clear search query
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  // Select brand filter
  void selectBrand(String? brand) {
    if (brand == state.selectedBrand) {
      // Toggle off if same brand selected
      state = state.copyWith(clearBrand: true);
    } else {
      state = state.copyWith(selectedBrand: brand);
    }
  }

  // Clear brand filter
  void clearBrand() {
    state = state.copyWith(clearBrand: true);
  }

  // Select category filter
  void selectCategory(String? category) {
    if (category == state.selectedCategory) {
      // Toggle off if same category selected
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  // Clear category filter
  void clearCategory() {
    state = state.copyWith(clearCategory: true);
  }

  // Clear all filters
  void clearAllFilters() {
    state = state.copyWith(
      searchQuery: '',
      clearBrand: true,
      clearCategory: true,
    );
  }
}

// Provider for multi-cart product search
final multiCartProductSearchProvider = StateNotifierProvider.autoDispose<
  ProductSearchNotifier,
  ProductSearchState
>((ref) => ProductSearchNotifier());

// Provider for single-cart product search
final singleCartProductSearchProvider = StateNotifierProvider.autoDispose<
  ProductSearchNotifier,
  ProductSearchState
>((ref) => ProductSearchNotifier());
