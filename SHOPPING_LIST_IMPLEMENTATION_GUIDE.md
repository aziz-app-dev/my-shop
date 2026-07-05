# Shopping List Multi-List Implementation Guide

## Overview
This guide documents the implementation of multiple shopping lists feature as per your requirements.

## ✅ Completed Changes

### 1. Model Updates ([lib/models/shopping_list_model.dart](lib/models/shopping_list_model.dart))

**Added:**
- `ShoppingList` class - Represents a shopping list itself
  - `id`, `name`, `createdAt`, `updatedAt`
  - `fromMap()`, `toMap()`, `copyWith()` methods

- Updated `ShoppingListItem` class:
  - Added `listId` field to reference which list the item belongs to
  - Updated `fromMap()` to handle backward compatibility (defaults `listId` to empty string)
  - Updated `toMap()` and `copyWith()` to include `listId`

### 2. Database Service Updates ([lib/view_models/services/database/database_services.dart](lib/view_models/services/database/database_services.dart))

**Added Box:**
- `_shoppingListsBoxName = 'shoppingLists'` - Stores the lists themselves
- Existing `_shoppingListBoxName = 'shoppingList'` - Stores the items

**New Methods in HiveService:**
```dart
// Shopping Lists Management
Future<List<ShoppingList>> getShoppingLists()
Future<void> createShoppingList(ShoppingList list)
Future<void> updateShoppingList(ShoppingList list)
Future<void> deleteShoppingList(String listId) // Also deletes all items
Future<void> duplicateShoppingList(String listId, String newListName)

// Shopping List Items (updated)
Future<List<ShoppingListItem>> getShoppingListItems(String listId) // Filter by list
Future<void> clearShoppedItems([String? listId]) // Optional listId parameter
```

**All methods also added to DatabaseService wrapper class.**

## 🔧 Required Changes (To Be Implemented)

### 3. State Update ([lib/view_models/states/shopping_list_state.dart](lib/view_models/states/shopping_list_state.dart))

**Current State:**
```dart
class ShoppingListState {
  final List<ShoppingListItem> items;
  final List<String> selectedItemIds;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  ...
}
```

**Needs to become:**
```dart
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

  // Add computed properties
  ShoppingList? get currentList {
    if (currentListId == null) return null;
    try {
      return lists.firstWhere((list) => list.id == currentListId);
    } catch (e) {
      return null;
    }
  }

  String get currentListName => currentList?.name ?? 'No List Selected';

  // Update copyWith and other methods to include new fields
}
```

### 4. Provider Update ([lib/view_models/providers/shopping_list_provider.dart](lib/view_models/providers/shopping_list_provider.dart))

**New Methods Needed:**
```dart
class ShoppingListNotifier extends StateNotifier<ShoppingListState> {
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

  // Update existing addProductToShoppingList to use currentListId
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

  // Similar updates for addCustomItemToShoppingList
  // Update clearShoppedItems to pass currentListId
  // etc.
}
```

### 5. Main Shopping List View Update ([lib/view/shopping_list/shopping_list_view.dart](lib/view/shopping_list/shopping_list_view.dart))

**Key Changes:**

1. **Remove the search bar from the main view** (search is in the separate search view)

2. **Add "More" menu in app bar:**
```dart
appBar: AppBarWidget.customAppBar(
  context: context,
  title: shoppingListState.currentListName, // Show current list name as title
  actions: [
    // More menu with list management
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'create') {
          _showCreateListDialog(context, shoppingListNotifier);
        } else if (value == 'duplicate') {
          _showDuplicateListDialog(context, shoppingListNotifier);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'create',
          child: Row(
            children: [
              Icon(Icons.add, color: Colors.blue),
              SizedBox(width: 8),
              Text('Create New List'),
            ],
          ),
        ),
        if (shoppingListState.currentListId != null)
          const PopupMenuItem(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy, color: Colors.green),
                SizedBox(width: 8),
                Text('Duplicate List'),
              ],
            ),
          ),
        const PopupMenuItemDivider(),

        // Show all lists with current one highlighted
        ...shoppingListState.lists.map((list) {
          final isCurrent = list.id == shoppingListState.currentListId;
          return PopupMenuItem(
            value: 'select_${list.id}',
            child: Row(
              children: [
                Icon(
                  isCurrent ? Icons.check_circle : Icons.circle_outlined,
                  color: isCurrent ? AppColors.primary : Colors.grey,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    list.name,
                    style: TextStyle(
                      color: isCurrent ? AppColors.primary : null,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                if (shoppingListState.lists.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, list.id, shoppingListNotifier);
                    },
                  ),
              ],
            ),
            onTap: isCurrent ? null : () {
              Navigator.pop(context);
              shoppingListNotifier.selectList(list.id);
            },
          );
        }).toList(),
      ],
    ),
  ],
),
```

3. **Update FAB to navigate to search view:**
```dart
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ShoppingListSearchView(),
      ),
    );
  },
  label: const Text('Add Items'),
  icon: const Icon(Icons.add),
),
```

4. **Add helper methods:**
```dart
void _showCreateListDialog(BuildContext context, ShoppingListNotifier notifier) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create New List'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'List Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.trim().isNotEmpty) {
              await notifier.createNewList(controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('List "${controller.text}" created')),
                );
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

void _showDuplicateListDialog(BuildContext context, ShoppingListNotifier notifier) {
  final currentList = ref.read(shoppingListProvider).currentList;
  if (currentList == null) return;

  final controller = TextEditingController(text: '${currentList.name} (Copy)');
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Duplicate List'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'New List Name',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (controller.text.trim().isNotEmpty) {
              await notifier.duplicateList(currentList.id, controller.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('List duplicated as "${controller.text}"')),
                );
              }
            }
          },
          child: const Text('Duplicate'),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmation(
  BuildContext context,
  String listId,
  ShoppingListNotifier notifier,
) {
  final list = ref.read(shoppingListProvider).lists.firstWhere((l) => l.id == listId);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete List'),
      content: Text('Are you sure you want to delete "${list.name}"? This will also delete all items in the list.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await notifier.deleteList(listId);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('List deleted')),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
```

### 6. Search View Update ([lib/view/shopping_list/shopping_list_search_view.dart](lib/view/shopping_list/shopping_list_search_view.dart))

**Simplified version without list management:**

1. Remove all list management UI (more menu, create list, duplicate, etc.)
2. Remove `_currentListName` - get it from provider instead
3. Update to show current list name from provider
4. Ensure items are added to the current selected list

**Example updates:**
```dart
// In build method, show current list
Container(
  child: Row(
    children: [
      Icon(Icons.list_alt, color: AppColors.primary),
      SizedBox(width: 8.w),
      smText(text: 'Adding to: '),
      smTextBold(
        text: ref.watch(shoppingListProvider).currentListName,
        color: AppColors.primary,
      ),
    ],
  ),
),

// When adding items, it will automatically use the currentListId from provider
await ref.read(shoppingListProvider.notifier).addProductToShoppingList(
  product: product,
  quantity: quantity,
);
```

## 📋 Implementation Checklist

- [x] Update `ShoppingListItem` model to include `listId`
- [x] Create `ShoppingList` model
- [x] Add shopping lists box to Hive
- [x] Implement database methods for list management
- [ ] Update `ShoppingListState` to include lists and currentListId
- [ ] Update `ShoppingListProvider` with new methods
- [ ] Redesign main shopping list view with list management
- [ ] Simplify search view to use provider's current list
- [ ] Test creating, selecting, duplicating, and deleting lists
- [ ] Test adding items to different lists
- [ ] Test switching between lists

## 🎯 User Flow

1. **Open Shopping List** → Shows current list items with list name as title
2. **Click More Icon (⋮)** → Shows dropdown with:
   - Create New List
   - Duplicate List
   - --- (divider) ---
   - List 1 (current - highlighted in primary color) [Delete icon]
   - List 2 [Delete icon]
   - List 3 [Delete icon]
3. **Click a list** → Switches to that list and shows its items
4. **Click Add Items FAB** → Opens search view
5. **In Search View** → Shows "Adding to: [Current List Name]"
6. **Search and add items** → Items are added to current list
7. **Return to main view** → See the updated list

## ⚠️ Important Notes

1. **Backward Compatibility**: The `listId` field in `ShoppingListItem.fromMap()` defaults to empty string for existing data.

2. **Default List**: When no lists exist, the app creates a default "My Shopping List".

3. **Deletion Protection**: Cannot delete a list if it's the only one remaining (enforce in UI).

4. **State Management**: Always reload items when switching lists to ensure fresh data.

5. **Search View**: Simplified to just add items - all list management is in the main view.

## 🚀 Next Steps

1. Update the state class with the new fields
2. Update the provider with the new methods
3. Redesign the main shopping list view UI
4. Update the search view to be simpler
5. Test thoroughly with multiple lists

All database infrastructure is ready. The remaining work is primarily UI and state management updates.
