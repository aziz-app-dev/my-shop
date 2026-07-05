import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/legacy.dart';

import '../../models/items_model.dart';
import '../services/database/database_services.dart';

// StateNotifier for products
class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final DatabaseService _databaseService;

  ProductsNotifier(this._databaseService) : super(const AsyncValue.loading()) {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _databaseService.getProducts());
  }

  Future<void> refreshProducts() async {
    await _loadProducts();
  }

  Future<void> addProduct(Product product) async {
    await _databaseService.addProduct(product);
    await _loadProducts(); // Reload after add
  }

  Future<void> updateProduct(Product product) async {
    await _databaseService.updateProduct(product);
    await _loadProducts(); // Reload after update
  }

  Future<void> deleteProduct(String id) async {
    await _databaseService.deleteProduct(id);
    await _loadProducts(); // Reload after delete
  }
}

// Provider for the notifier
final productsNotifierProvider =
    StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
      final databaseService = ref.watch(databaseServiceProvider);
      return ProductsNotifier(databaseService);
    });

// Auto-dispose provider to watch products data
final productsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(productsNotifierProvider);
});
