import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../models/items_model.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/product_card.dart';
import '../../../res/components/text_field_widget.dart';
import '../../../view_models/providers/multi_cart_provider.dart';
import '../../../view_models/providers/sales_provider.dart';
import '../../../view_models/providers/product_search_provider.dart';
import '../../../view_models/services/keyboard/app_keyboard_service.dart';

class ProductsSectionWithSearch extends ConsumerStatefulWidget {
  const ProductsSectionWithSearch({super.key});

  @override
  ConsumerState<ProductsSectionWithSearch> createState() =>
      _ProductsSectionWithSearchState();
}

class _ProductsSectionWithSearchState
    extends ConsumerState<ProductsSectionWithSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // --- Keyboard navigation (Tab / arrows / Enter, Esc to clear). ---
  /// Index in [_liveProducts] of the keyboard-selected product.
  int? _focusedProductIndex;
  int _gridColumns = 1; // visible columns, updated on every build
  final GlobalKey _selectedItemKey =
      GlobalKey(); // reused key for scroll-into-view

  /// Products currently shown (search result), updated on every build so the
  /// keyboard handler always navigates over the *visible* products.
  List<Product>? _liveProducts;

  /// Sales-screen shortcut scope for the multi-cart page. Window-level,
  /// focus-independent (the visible page wins over other scopes).
  late final AppKeyboardScope _keys = AppKeyboardScope(
    'multi-cart-products',
    _handleKey,
  );

  /// Adds the given [product] to the active multi-cart, or warns when it is
  /// out of stock. The raw action, shared by the card tap and the Enter
  /// paths.
  void _addProductToCart(Product product) {
    if (!product.isService && product.stock != null && product.stock! <= 0) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: mdTextBold(text: 'Out of Stock'),
              content: smText(
                maxLines: 3,
                text: '${product.name} is currently out of stock.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: mdTextBold(text: 'OK'),
                ),
              ],
            ),
      );
    } else {
      ref.read(multiCartProvider.notifier).addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  bool _handleKey(KeyEvent event) {
    // Don't hijack typing: while a text field has focus (e.g. the search box)
    // keys must reach it instead of firing products into the cart.
    final focusWidget = FocusManager.instance.primaryFocus?.context?.widget;
    if (focusWidget is EditableText) return false;

    final products = _liveProducts;
    if (products == null || products.isEmpty) return false;

    // --- Tab / arrow / Enter navigation over the visible products ---
    // Shift+Tab keeps its normal focus-traversal meaning.
    if (HardwareKeyboard.instance.isShiftPressed) return false;

    if (_focusedProductIndex == null) {
      if (_isNavPress(event, LogicalKeyboardKey.tab) ||
          _isNavPress(event, LogicalKeyboardKey.arrowDown) ||
          _isNavPress(event, LogicalKeyboardKey.arrowRight)) {
        _setKeyboardSelection(0);
        return true;
      }
      return false;
    }

    final selected = _focusedProductIndex!;
    if (selected >= products.length) {
      _clearKeyboardSelection();
      return false;
    }

    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.enter) ||
        AppKeyboardScope.didPress(event, LogicalKeyboardKey.numpadEnter)) {
      // Ctrl+Enter belongs to the page-level "complete sale" shortcut.
      if (HardwareKeyboard.instance.isControlPressed) return false;
      _addProductToCart(products[selected]);
      _setKeyboardSelection(
        (selected + _gridColumns).clamp(0, products.length - 1),
      );
      return true;
    }
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.escape)) {
      _clearKeyboardSelection();
      return true;
    }
    if (_isNavPress(event, LogicalKeyboardKey.tab) ||
        _isNavPress(event, LogicalKeyboardKey.arrowRight)) {
      _setKeyboardSelection(
        selected == products.length - 1 ? 0 : selected + 1,
      );
      return true;
    }
    if (_isNavPress(event, LogicalKeyboardKey.arrowLeft)) {
      _setKeyboardSelection(
        selected == 0 ? products.length - 1 : selected - 1,
      );
      return true;
    }
    if (_isNavPress(event, LogicalKeyboardKey.arrowDown)) {
      _setKeyboardSelection(
        (selected + _gridColumns).clamp(0, products.length - 1),
      );
      return true;
    }
    if (_isNavPress(event, LogicalKeyboardKey.arrowUp)) {
      _setKeyboardSelection(
        (selected - _gridColumns).clamp(0, products.length - 1),
      );
      return true;
    }
    return false;
  }

  /// Arrow / Tab navigation is allowed to auto-repeat while held.
  bool _isNavPress(KeyEvent event, LogicalKeyboardKey key) =>
      (event is KeyDownEvent || event is KeyRepeatEvent) &&
      event.logicalKey == key;

  void _clearKeyboardSelection() {
    if (mounted && _focusedProductIndex != null) {
      setState(() => _focusedProductIndex = null);
    }
  }

  /// Selects [index] in the visible product list (clamped) and scrolls it
  /// into view.
  void _setKeyboardSelection(int index) {
    final count = _liveProducts?.length ?? 0;
    if (count == 0) return;
    setState(() => _focusedProductIndex = index.clamp(0, count - 1));
    _revealSelectedItem();
  }

  void _revealSelectedItem() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _selectedItemKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    AppKeyboardScope.register(_keys);

    // Focus the search bar as soon as the page opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });

    // Tab inside the search box jumps into the product grid selection.
    _searchFocusNode.onKeyEvent = (node, event) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.tab) {
        final products = _liveProducts;
        if (products != null && products.isNotEmpty) {
          _setKeyboardSelection(0);
          _searchFocusNode.unfocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      }
      return KeyEventResult.ignored;
    };
  }

  // Cache brand/category extraction so it only recomputes when the product
  // list itself changes — not on every search keystroke or rebuild.
  List<Product>? _cachedSource;
  List<String> _cachedBrands = const [];
  List<String> _cachedCategories = const [];

  void _ensureFilterOptions(List<Product> products) {
    if (identical(_cachedSource, products)) return;
    _cachedSource = products;
    _cachedBrands = _getUniqueBrands(products);
    _cachedCategories = _getUniqueCategories(products);
  }

  @override
  void dispose() {
    AppKeyboardScope.unregister(_keys);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(
    List<Product> products,
    String searchQuery,
    String? selectedBrand,
    String? selectedCategory,
  ) {
    var filtered = products;

    // Filter by brand
    if (selectedBrand != null && selectedBrand.isNotEmpty) {
      filtered =
          filtered.where((product) => product.brand == selectedBrand).toList();
    }

    // Filter by category
    if (selectedCategory != null && selectedCategory.isNotEmpty) {
      filtered =
          filtered
              .where((product) => product.category == selectedCategory)
              .toList();
    }

    // Filter by search query (also search by barcode)
    if (searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      filtered =
          filtered.where((product) {
            final nameLower = product.name.toLowerCase();
            final descriptionLower = product.description?.toLowerCase() ?? '';
            final barcodeLower = product.barcode?.toLowerCase() ?? '';
            return nameLower.contains(queryLower) ||
                descriptionLower.contains(queryLower) ||
                barcodeLower.contains(queryLower);
          }).toList();
    }

    return filtered;
  }

  // Extract unique brands from products
  List<String> _getUniqueBrands(List<Product> products) {
    return products
        .where((p) => p.brand != null && p.brand!.isNotEmpty)
        .map((p) => p.brand!)
        .toSet()
        .toList()
      ..sort();
  }

  // Extract unique categories from products
  List<String> _getUniqueCategories(List<Product> products) {
    return products
        .where((p) => p.category != null && p.category!.isNotEmpty)
        .map((p) => p.category!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Horizontally scrollable filter chips row with an "All" option.
  Widget _buildChipsRow({
    required List<String> items,
    required String? selected,
    required VoidCallback onSelectAll,
    required void Function(String) onSelect,
  }) {
    return Container(
      height: 40.spMin,
      margin: EdgeInsets.only(bottom: 4.spMin),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.spMin),
        itemCount: items.length + 1, // +1 for "All"
        itemBuilder: (context, index) {
          final bool isAll = index == 0;
          final String? value = isAll ? null : items[index - 1];
          final bool isSelected = isAll ? selected == null : selected == value;
          return Padding(
            padding: EdgeInsets.only(right: 8.spMin),
            child: FilterChip(
              label: Text(
                isAll ? 'All' : value!,
                style: TextStyle(
                  fontSize: 12.spMin,
                  color: isSelected ? Colors.white : null,
                ),
              ),
              selected: isSelected,
              showCheckmark: false,
              side: BorderSide.none,
              onSelected: (_) => isAll ? onSelectAll() : onSelect(value!),
              backgroundColor:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.grey800
                      : AppColors.grey200,
              selectedColor: AppColors.primary,
              padding: EdgeInsets.symmetric(horizontal: 8.spMin),
            ),
          );
        },
      ),
    );
  }

  /// Opens a popup dialog to pick a brand / category, with a "Clear all".
  void _showFilterDialog(
    BuildContext context,
    List<String> brands,
    List<String> categories,
  ) {
    final bool hasOptions = brands.isNotEmpty || categories.isNotEmpty;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final state = ref.watch(multiCartProductSearchProvider);
            final notifier = ref.read(multiCartProductSearchProvider.notifier);
            return AlertDialog(
              titlePadding: EdgeInsets.fromLTRB(
                20.spMin,
                16.spMin,
                12.spMin,
                0,
              ),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      mdTextBold(text: 'Filters'),
                      if (hasOptions)
                        TextButton.icon(
                          onPressed: () {
                            notifier.clearAllFilters();
                            Navigator.pop(dialogContext);
                          },
                          icon: Icon(TablerIcons.filter_off, size: 18.spMin),
                          label: Text(
                            'Clear all',
                            style: TextStyle(fontSize: 12.spMin),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10.spMin),
                  Divider(height: 1, color: AppColors.grey400),
                ],
              ),
              contentPadding: EdgeInsets.fromLTRB(
                20.spMin,
                16.spMin,
                20.spMin,
                8.spMin,
              ),
              content: SizedBox(
                width: 320.spMin,
                child:
                    !hasOptions
                        ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.spMin),
                          child: smText(
                            text: 'No filters available',
                            color: Colors.grey,
                          ),
                        )
                        : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (categories.isNotEmpty) ...[
                                mdTextBold(text: 'Category'),
                                SizedBox(height: 8.spMin),
                                Wrap(
                                  spacing: 8.spMin,
                                  runSpacing: 8.spMin,
                                  children: [
                                    for (final category in categories)
                                      FilterChip(
                                        label: Text(
                                          category,
                                          style: TextStyle(fontSize: 12.spMin),
                                        ),
                                        selected:
                                            state.selectedCategory == category,
                                        selectedColor: AppColors.primary,
                                        showCheckmark: false,
                                        side: BorderSide.none,
                                        onSelected:
                                            (_) => notifier.selectCategory(
                                              category,
                                            ),
                                      ),
                                  ],
                                ),
                              ],
                              if (brands.isNotEmpty) ...[
                                SizedBox(height: 16.spMin),
                                mdTextBold(text: 'Brand'),
                                SizedBox(height: 8.spMin),
                                Wrap(
                                  spacing: 8.spMin,
                                  runSpacing: 8.spMin,
                                  children: [
                                    for (final brand in brands)
                                      FilterChip(
                                        label: Text(
                                          brand,
                                          style: TextStyle(fontSize: 12.spMin),
                                        ),
                                        selected: state.selectedBrand == brand,
                                        selectedColor: AppColors.primary,
                                        showCheckmark: false,
                                        side: BorderSide.none,
                                        onSelected:
                                            (_) => notifier.selectBrand(brand),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
              ),
              actionsPadding: EdgeInsets.fromLTRB(
                20.spMin,
                0,
                16.spMin,
                12.spMin,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Done', style: TextStyle(fontSize: 12.spMin)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsFutureProvider);
    final searchState = ref.watch(multiCartProductSearchProvider);
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error:
          (error, stack) => Center(
            child: Text('Error: $error', style: TextStyle(fontSize: 16.spMin)),
          ),
      data: (products) {
        _ensureFilterOptions(products);
        final brands = _cachedBrands;
        final categories = _cachedCategories;
        final filteredProducts = _filterProducts(
          products,
          searchState.searchQuery,
          searchState.selectedBrand,
          searchState.selectedCategory,
        );

        _liveProducts = filteredProducts;

        return Column(
          children: [
            // Search Bar with Filter + Barcode Scanner. Buttons match the
            // field height via IntrinsicHeight (no fixed-height SizedBox that
            // would clip the text field and overflow).
            Padding(
              padding: EdgeInsets.fromLTRB(16.spMin, 12.spMin, 16.spMin, 6.spMin),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        hintText: 'Search products ...',
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        prefixIcon: Icon(
                          TablerIcons.search,
                          size: 20.spMin,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : AppColors.lIconColor,
                        ),
                        // Clear + Filter live INSIDE the search field now (no
                        // separate filter button beside it).
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (searchState.searchQuery.isNotEmpty)
                              IconButton(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Clear',
                                icon: Icon(TablerIcons.x, size: 20.spMin),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(
                                        multiCartProductSearchProvider.notifier,
                                      )
                                      .clearSearch();
                                },
                              ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Filters',
                              icon: Icon(
                                TablerIcons.filter,
                                size: 20.spMin,
                                color:
                                    (searchState.selectedBrand != null ||
                                            searchState.selectedCategory != null)
                                        ? AppColors.primary
                                        : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : AppColors.lIconColor),
                              ),
                              onPressed:
                                  () => _showFilterDialog(
                                    context,
                                    brands,
                                    categories,
                                  ),
                            ),
                            SizedBox(width: 4.spMin),
                          ],
                        ),
                        onChange: (value) {
                          // A new query invalidates the previous selection.
                          _clearKeyboardSelection();
                          ref
                              .read(multiCartProductSearchProvider.notifier)
                              .updateSearchQuery(value!);
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          // Enter while still typing in the search box: when
                          // the query matched exactly ONE product, send it
                          // straight to the cart.
                          final products = _liveProducts;
                          if (products != null && products.length == 1) {
                            _addProductToCart(products.first);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter Row (chips under the search bar) — hidden while
            // searching so the results get the full space.
            if (categories.isNotEmpty && searchState.searchQuery.isEmpty)
              _buildChipsRow(
                items: categories,
                selected: searchState.selectedCategory,
                onSelectAll:
                    () =>
                        ref
                            .read(multiCartProductSearchProvider.notifier)
                            .clearCategory(),
                onSelect:
                    (category) => ref
                        .read(multiCartProductSearchProvider.notifier)
                        .selectCategory(category),
              ),

            // Products Grid
            Expanded(
              child:
                  filteredProducts.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TablerIcons.search_off,
                              size: 48.spMin,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              searchState.searchQuery.isEmpty &&
                                      searchState.selectedBrand == null &&
                                      searchState.selectedCategory == null
                                  ? 'No items available'
                                  : searchState.searchQuery.isNotEmpty
                                  ? 'No products found for "${searchState.searchQuery}"'
                                  : searchState.selectedBrand != null
                                  ? 'No products found for brand "${searchState.selectedBrand}"'
                                  : 'No products found for category "${searchState.selectedCategory}"',
                              style: TextStyle(
                                fontSize: 14.spMin,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                      : LayoutBuilder(
                        builder: (context, constraints) {
                          // Size cards off the section's OWN width (not the
                          // whole screen) so they stay consistent whether or not
                          // the cart panel is showing beside them. Capping the
                          // max card width lets the column count adapt.
                          //
                          // `maxCrossAxisExtent` is a pixel value → `.spMin`.
                          // `childAspectRatio` is a pure ratio → NOT scaled.
                          final double maxCardWidth =
                              isMobile ? 130.spMin : 170.spMin;
                          final double spacing = 8.spMin;
                          // Real column count of the grid — needed for
                          // Up/Down navigation.
                          _gridColumns =
                              ((constraints.maxWidth + spacing) ~/
                                      (maxCardWidth + spacing))
                                  .clamp(1, filteredProducts.length);
                          return GridView.builder(
                            padding: EdgeInsets.all(8.spMin),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: maxCardWidth,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final bool isKeyboardSelected =
                                  _focusedProductIndex == index;
                              ProductCard card = ProductCard(
                                product: product,
                                isHighlighted: isKeyboardSelected,
                                onTap: () => _addProductToCart(product),
                              );
                              if (isKeyboardSelected) {
                                // One reusable key on the selected card so
                                // keyboard navigation can scroll it into view.
                                return KeyedSubtree(
                                  key: _selectedItemKey,
                                  child: card,
                                );
                              }
                              return card;
                            },
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}

// Keep the old function for backwards compatibility
Widget buildProductsSection(WidgetRef ref) {
  return const ProductsSectionWithSearch();
}
