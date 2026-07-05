import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shopping_list_model.dart';
import '../../models/items_model.dart';
import '../services/database/database_services.dart';
import '../states/shopping_list_state.dart';
import 'product_view.dart';
import 'home_page_provider.dart';
import 'package:riverpod/legacy.dart';

final shoppingListProvider =
    StateNotifierProvider<ShoppingListNotifier, ShoppingListState>((ref) {
      return ShoppingListNotifier(ref);
    });

class ShoppingListNotifier extends StateNotifier<ShoppingListState> {
  final Ref _ref;

  ShoppingListNotifier(this._ref) : super(ShoppingListState()) {
    loadShoppingLists();
  }

  final DatabaseService _dbService = DatabaseService();

  // Load all lists and select first one by default
  Future<void> loadShoppingLists() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      var lists = await _dbService.getShoppingLists();

      // If no lists exist, create a default one
      if (lists.isEmpty) {
        final defaultList = ShoppingList(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'My Shopping List',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _dbService.createShoppingList(defaultList);
        lists = [defaultList];
      }

      final currentListId = lists.first.id;
      final items = await _dbService.getShoppingListItems(currentListId);

      state = state.copyWith(
        lists: lists,
        currentListId: currentListId,
        items: items,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // Keep for backward compatibility
  Future<void> loadShoppingList() async {
    await loadShoppingLists();
  }

  // Switch to a different list
  Future<void> selectList(String listId) async {
    try {
      final items = await _dbService.getShoppingListItems(listId);
      state = state.copyWith(
        currentListId: listId,
        items: items,
        selectedItemIds: [], // Clear selections when switching lists
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Create new list
  Future<void> createNewList(String listName) async {
    try {
      final newList = ShoppingList(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: listName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _dbService.createShoppingList(newList);
      await loadShoppingLists();

      // Automatically switch to the new list
      await selectList(newList.id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Duplicate list
  Future<void> duplicateList(String listId, String newListName) async {
    try {
      await _dbService.duplicateShoppingList(listId, newListName);
      await loadShoppingLists();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Delete list
  Future<void> deleteList(String listId) async {
    try {
      await _dbService.deleteShoppingList(listId);
      await loadShoppingLists(); // Will auto-select first list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addProductToShoppingList({
    required Product product,
    required int quantity,
  }) async {
    if (state.currentListId == null) {
      state = state.copyWith(error: 'No list selected');
      return;
    }

    try {
      final item = ShoppingListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        listId: state.currentListId!, // Add to current list
        productId: product.id,
        productName: product.name,
        productImageUrl: product.imageUrl,
        quantityNeeded: quantity,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        price: product.price,
        brand: product.brand,
      );

      await _dbService.addToShoppingList(item);

      // Reload items for current list
      final items = await _dbService.getShoppingListItems(state.currentListId!);
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> addCustomItemToShoppingList({
    required String itemName,
    required int quantity,
  }) async {
    if (state.currentListId == null) {
      state = state.copyWith(error: 'No list selected');
      return;
    }

    try {
      final item = ShoppingListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        listId: state.currentListId!, // Add to current list
        productId: '',
        productName: itemName,
        quantityNeeded: quantity,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dbService.addToShoppingList(item);

      // Reload items for current list
      final items = await _dbService.getShoppingListItems(state.currentListId!);
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (state.currentListId == null) return;

    try {
      final item = state.items.firstWhere((item) => item.id == itemId);
      final updatedItem = item.copyWith(
        quantityNeeded: newQuantity,
        updatedAt: DateTime.now(),
      );

      await _dbService.updateShoppingListItem(updatedItem);

      // Reload items for current list
      final items = await _dbService.getShoppingListItems(state.currentListId!);
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteItem(String itemId) async {
    if (state.currentListId == null) return;

    try {
      await _dbService.deleteShoppingListItem(itemId);

      // Reload items for current list
      final items = await _dbService.getShoppingListItems(state.currentListId!);
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void toggleItemSelection(String itemId) {
    final selectedIds = List<String>.from(state.selectedItemIds);
    if (selectedIds.contains(itemId)) {
      selectedIds.remove(itemId);
    } else {
      selectedIds.add(itemId);
    }
    state = state.copyWith(selectedItemIds: selectedIds);
  }

  void selectAll() {
    final unshoppedIds = state.unshoppedItems.map((item) => item.id).toList();
    state = state.copyWith(selectedItemIds: unshoppedIds);
  }

  void deselectAll() {
    state = state.copyWith(selectedItemIds: []);
  }

  Future<void> markSelectedAsShopped() async {
    if (state.selectedItemIds.isEmpty) return;

    try {
      await _dbService.markItemsAsShopped(state.selectedItemIds);

      // Update product stocks
      for (final itemId in state.selectedItemIds) {
        final item = state.items.firstWhere((item) => item.id == itemId);
        if (item.productId.isNotEmpty) {
          // Get the product and update its stock
          final products = await _dbService.getProducts();
          final product = products.firstWhere(
            (p) => p.id == item.productId,
            orElse:
                () => Product(
                  id: '',
                  name: '',
                  price: 0,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
          );

          if (product.id.isNotEmpty && product.stock != null) {
            final updatedProduct = Product(
              id: product.id,
              name: product.name,
              price: product.price,
              stock: (product.stock ?? 0) + item.quantityNeeded,
              description: product.description,
              imageUrl: product.imageUrl,
              isService: product.isService,
              purchasePrice: product.purchasePrice,
              isBackup: product.isBackup,
              createdAt: product.createdAt,
              updatedAt: DateTime.now(),
              warranty: product.warranty,
              condition: product.condition,
              brand: product.brand,
              category: product.category,
              fieldConfigs: product.fieldConfigs,
            );

            await _dbService.updateProduct(updatedProduct);
          }
        }
      }

      state = state.copyWith(selectedItemIds: []);

      // Reload items for current list
      if (state.currentListId != null) {
        final items = await _dbService.getShoppingListItems(
          state.currentListId!,
        );
        state = state.copyWith(items: items);
      }

      // Refresh products in all providers to update stock across the app
      _ref.read(productsNotifierProvider.notifier).refreshProducts();
      _ref.read(homePageProvider.notifier).refreshProducts();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> clearShoppedItems() async {
    if (state.currentListId == null) return;

    try {
      await _dbService.clearShoppedItems(state.currentListId);

      // Reload items for current list
      final items = await _dbService.getShoppingListItems(state.currentListId!);
      state = state.copyWith(items: items);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
