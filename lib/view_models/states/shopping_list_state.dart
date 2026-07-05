import '../../models/shopping_list_model.dart';

class ShoppingListState {
  final List<ShoppingList> lists; // All shopping lists
  final String? currentListId; // Currently selected list
  final List<ShoppingListItem> items; // Items in current list
  final List<String> selectedItemIds;
  final bool isLoading;
  final String? error;
  final String searchQuery;

  ShoppingListState({
    this.lists = const [],
    this.currentListId,
    this.items = const [],
    this.selectedItemIds = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
  });

  List<ShoppingListItem> get filteredItems {
    if (searchQuery.isEmpty) return items;

    return items.where((item) {
      return item.productName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (item.brand?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  List<ShoppingListItem> get unshoppedItems {
    return filteredItems.where((item) => !item.isShopped).toList();
  }

  List<ShoppingListItem> get shoppedItems {
    return filteredItems.where((item) => item.isShopped).toList();
  }

  int get totalItems => items.length;
  int get shoppedCount => items.where((item) => item.isShopped).length;
  int get unshoppedCount => items.where((item) => !item.isShopped).length;

  // Get current list
  ShoppingList? get currentList {
    if (currentListId == null) return null;
    try {
      return lists.firstWhere((list) => list.id == currentListId);
    } catch (e) {
      return null;
    }
  }

  String get currentListName => currentList?.name ?? 'Shopping List';

  ShoppingListState copyWith({
    List<ShoppingList>? lists,
    String? currentListId,
    List<ShoppingListItem>? items,
    List<String>? selectedItemIds,
    bool? isLoading,
    String? error,
    String? searchQuery,
  }) {
    return ShoppingListState(
      lists: lists ?? this.lists,
      currentListId: currentListId ?? this.currentListId,
      items: items ?? this.items,
      selectedItemIds: selectedItemIds ?? this.selectedItemIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
