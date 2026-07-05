import '../../models/items_model.dart';
import '../services/database/database_services.dart';
import '../states/product_details_state.dart';
import 'package:riverpod/legacy.dart';

class ProductDetailsNotifier extends StateNotifier<ProductDetailsState> {
  final DatabaseService _dbService;
  final Product product;

  ProductDetailsNotifier(this._dbService, this.product)
    : super(ProductDetailsState(isLoading: true)) {
    loadProductDetails();
  }

  Future<void> loadProductDetails() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load all data in parallel
      await Future.wait([
        _loadProductStats(),
        _loadBrandLogo(),
        _loadRelatedProducts(),
      ]);

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _loadProductStats() async {
    try {
      final bills = await _dbService.getBills();
      final Set<String> uniqueCustomers = {};
      int totalQuantity = 0;
      double revenue = 0.0;

      for (final bill in bills) {
        if (bill.quantities.containsKey(product.id)) {
          if (bill.customerId != null && bill.customerId!.isNotEmpty) {
            uniqueCustomers.add(bill.customerId!);
          } else if (bill.customerName != null &&
              bill.customerName!.isNotEmpty) {
            uniqueCustomers.add(bill.customerName!);
          }

          final quantity = bill.quantities[product.id] ?? 0;
          totalQuantity += quantity;
          revenue += product.price * quantity;
        }
      }

      state = state.copyWith(
        customerCount: uniqueCustomers.length,
        totalSold: totalQuantity,
        totalRevenue: revenue,
      );
    } catch (e) {
      // Handle stats loading error without blocking other data
      state = state.copyWith(customerCount: 0, totalSold: 0, totalRevenue: 0.0);
    }
  }

  Future<void> _loadBrandLogo() async {
    if (product.brand != null && product.brand != 'No Brand') {
      try {
        final brands = await _dbService.getBrands();
        final brand = brands.firstWhere(
          (b) => b.name == product.brand,
          orElse:
              () =>
                  brands.isNotEmpty
                      ? brands.first
                      : throw Exception('No brands found'),
        );

        if (brand.name == product.brand) {
          state = state.copyWith(brandLogoUrl: brand.imageUrl);
        }
      } catch (e) {
        // Brand logo is optional, don't fail if it doesn't load
        state = state.copyWith(brandLogoUrl: null);
      }
    }
  }

  Future<void> _loadRelatedProducts() async {
    try {
      final allProducts = await _dbService.getProducts();

      if (product.isService) {
        // For a service, show the top-selling services (by quantity sold).
        final bills = await _dbService.getBills();
        final Map<String, int> salesCount = {};
        for (final bill in bills) {
          for (final entry in bill.quantities.entries) {
            salesCount[entry.key] = (salesCount[entry.key] ?? 0) + entry.value;
          }
        }

        final services =
            allProducts
                .where((p) => p.isService && p.id != product.id)
                .toList()
              ..sort(
                (a, b) =>
                    (salesCount[b.id] ?? 0).compareTo(salesCount[a.id] ?? 0),
              );

        state = state.copyWith(relatedProducts: services.take(6).toList());
        return;
      }

      // For an item, show other products from the same brand.
      if (product.brand != null && product.brand != 'No Brand') {
        final related =
            allProducts
                .where((p) => p.brand == product.brand && p.id != product.id)
                .take(6)
                .toList();
        state = state.copyWith(relatedProducts: related);
      } else {
        state = state.copyWith(relatedProducts: []);
      }
    } catch (e) {
      // Related products are optional
      state = state.copyWith(relatedProducts: []);
    }
  }

  Future<void> refreshDetails() async {
    await loadProductDetails();
  }
}

// Provider factory that takes a Product parameter
final productDetailsProvider = StateNotifierProvider.family<
  ProductDetailsNotifier,
  ProductDetailsState,
  Product
>((ref, product) {
  return ProductDetailsNotifier(DatabaseService(), product);
});
