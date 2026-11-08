import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/res/components/empty_widget.dart';
import 'package:desktopapp/res/components/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../models/items_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../utils/platform_utils.dart';
import '../../../view_models/providers/sales_provider.dart';
import '../../../view_models/providers/product_search_provider.dart';
import '../../../view_models/services/keyboard/app_keyboard_service.dart';
import '../../../res/components/product_card.dart';
import '../../../res/components/app_flushbar.dart';
import '../../product_details/product_details_view.dart';

/// Shared height for the search field and the action buttons next to it, so
/// they line up exactly across desktop / tablet / mobile. (Passed through
/// `.spMin` at use sites.)
const double _kSearchBarHeight = 48;

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

  // --- Keyboard navigation (Tab / arrows / Enter, Esc to clear). The user
  // can walk the visible items without the mouse.
  //
  /// Index in [_liveProducts] of the keyboard-selected product. Null until
  /// the user presses Tab/arrows; cleared on Escape or on a new query.
  int? _focusedProductIndex;
  int _gridColumns = 1; // visible columns, updated on every build
  final GlobalKey _selectedItemKey =
      GlobalKey(); // reused key for scroll-into-view

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

  /// Adds the given [product] to the cart, or warns when it is out of stock.
  /// The raw action — no focus guards — shared by the card tap handler and
  /// the Enter-on-single-result path so all entry points behave identically.
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
      ref.read(salesProvider.notifier).addToCart(product);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  /// Click entry point. Never hijack keys while the user is typing
  /// in the search box.
  void _handleProductTap(Product product) {
    if (_searchFocusNode.hasFocus) return;
    _addProductToCart(product);
  }

  /// Dropdown menu on the card's caret button. Order matches the user's
  /// request: 1) Sale — put the item in the cart, 2) Details, 3) Stock.
  Future<void> _showProductMenu(
    BuildContext context,
    Product product,
    Offset position,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'cart',
          child: Row(
            children: [
              Icon(
                TablerIcons.shopping_cart_plus,
                size: 18.spMin,
                color: AppColors.primary,
              ),
              SizedBox(width: 10.spMin),
              Text('Sale — Add to Cart', style: TextStyle(fontSize: 13.spMin)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'details',
          child: Row(
            children: [
              Icon(
                TablerIcons.info_circle,
                size: 18.spMin,
                color: AppColors.primary,
              ),
              SizedBox(width: 10.spMin),
              Text('Details', style: TextStyle(fontSize: 13.spMin)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'stock',
          child: Row(
            children: [
              Icon(
                TablerIcons.database,
                size: 18.spMin,
                color: AppColors.primary,
              ),
              SizedBox(width: 10.spMin),
              Text('Stock', style: TextStyle(fontSize: 13.spMin)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;
    switch (selected) {
      case 'cart':
        _handleProductTap(product);
        break;
      case 'details':
        _openProductDetails(context, product);
        break;
      case 'stock':
        _showStockDialog(context, product);
        break;
    }
  }

  /// Opens the product details screen (same navigation as double-tapping the
  /// card elsewhere in the app).
  Future<void> _openProductDetails(
    BuildContext context,
    Product product,
  ) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
    if (!context.mounted) return;
    if (result is Map && result['success'] == true) {
      AppFlushbar.success(
        context,
        message: result['message'] ?? 'Product updated successfully!',
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Quick stock view: current quantity, reorder level and a coloured status
  /// line. Services show a "no stock" line instead.
  void _showStockDialog(BuildContext context, Product product) {
    final isService = product.isService;
    final stock = product.stock;
    final reorderLevel = product.reorderLevel ?? 5;

    final String statusText;
    final Color statusColor;
    if (isService) {
      statusText = 'Service — stock not tracked';
      statusColor = Colors.blue;
    } else if (stock == null) {
      statusText = 'No stock recorded';
      statusColor = Colors.orange;
    } else if (stock <= 0) {
      statusText = 'Out of stock';
      statusColor = Colors.red;
    } else if (stock <= reorderLevel) {
      statusText = 'Low stock (reorder at $reorderLevel)';
      statusColor = Colors.orange;
    } else {
      statusText = 'In stock';
      statusColor = Colors.green;
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: mdTextBold(text: product.name, maxLines: 2),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8.h,
              children: [
                smText(
                  text: isService ? 'Type: Service' : 'Type: Product',
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.grey300
                          : AppColors.grey700,
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: mdTextBold(text: 'Close'),
              ),
            ],
          ),
    );
  }

  /// Products currently shown (search result), updated on every build so the
  /// keyboard handler always navigates over the *visible* products.
  List<Product>? _liveProducts;

  /// Sales-screen shortcut scope (Tab / arrows / Enter navigate the product
  /// grid, Esc clears). Handled by the window-level keyboard dispatcher
  /// (see [AppKeyboardScope]) — focus-independent. Registered later than the
  /// main-nav scope, so it wins over the section navigation while this
  /// page is on screen.
  late final AppKeyboardScope _keys = AppKeyboardScope(
    'sales-products',
    _handleKey,
  );

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
      // Nothing selected yet — Tab / Down / Right start on the first item.
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
      // Stale selection (list shrank) — drop it.
      _clearKeyboardSelection();
      return false;
    }

    // Enter (fresh press only) sends the selected product straight to the
    // cart, then moves the selection one step down so a held row of items
    // can be rung up with a few Enters. Ctrl+Enter is left alone — it
    // belongs to the page-level "complete sale" shortcut.
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.enter) ||
        AppKeyboardScope.didPress(event, LogicalKeyboardKey.numpadEnter)) {
      if (HardwareKeyboard.instance.isControlPressed) return false;
      _addProductToCart(products[selected]);
      _setKeyboardSelection((selected + _gridColumns).clamp(
        0,
        products.length - 1,
      ));
      return true;
    }
    // Escape clears the selection.
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.escape)) {
      _clearKeyboardSelection();
      return true;
    }
    // Tab / Right move forward, Left backward — both wrap around.
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
    // Up / Down move a whole grid row.
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

  /// Arrow / Tab navigation is allowed to auto-repeat while held (unlike
  /// one-shot actions such as Enter that must not fire several times in a
  /// row).
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

    // Focus the search bar as soon as the page opens, so the user can start
    // typing (or scan a barcode) without touching the mouse first.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });

    // Tab inside the search box jumps into the product grid selection, so the
    // user can walk the items with the keyboard instead of the mouse.
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

  /// Find product by barcode
  Product? _findProductByBarcode(List<Product> products, String barcode) {
    try {
      return products.firstWhere(
        (p) =>
            p.barcode != null &&
            p.barcode!.toLowerCase() == barcode.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Open barcode scanner
  Future<void> _openBarcodeScanner(
    BuildContext context,
    List<Product> products,
    WidgetRef ref,
  ) async {
    // mobile_scanner has no desktop implementation; show a hint instead of
    // crashing with a MissingPluginException.
    if (!PlatformUtils.isMobile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera scanning is only available on mobile. On desktop, use a '
            'USB barcode scanner into the search box.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    debugPrint('🔍 Barcode scanned: $result');
    debugPrint('🔍 Total products to search: ${products.length}');

    if (!context.mounted) return;

    // Show what was scanned for debugging
    if (result == null || result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan cancelled or no barcode detected'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final product = _findProductByBarcode(products, result);
    debugPrint('🔍 Product found: ${product?.name ?? "NULL"}');

    if (product != null) {
      // Check stock
      if (!product.isService && product.stock != null && product.stock! <= 0) {
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
        // Add to cart
        debugPrint('🛒 Adding to cart: ${product.name}');
        ref.read(salesProvider.notifier).addToCart(product);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } else {
      // Product not found - show dialog with scanned barcode
      final productsWithBarcodes =
          products
              .where((p) => p.barcode != null && p.barcode!.isNotEmpty)
              .length;

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: mdTextBold(text: 'Product Not Found'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  smText(text: 'Scanned barcode:', maxLines: 1),
                  SizedBox(height: 4.h),
                  SelectableText(
                    result,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.spMin,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  smText(
                    text: 'Products with barcodes: $productsWithBarcodes',
                    maxLines: 1,
                  ),
                  SizedBox(height: 8.h),
                  smText(
                    text: 'Make sure the product has this barcode saved.',
                    maxLines: 2,
                    color: Colors.grey,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: mdTextBold(text: 'OK'),
                ),
              ],
            ),
      );
    }
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

  /// Action button (filter / scanner) — stretches to the search field height
  /// when placed inside an [IntrinsicHeight] row (fixed width, full height).
  Widget _buildActionButton({
    required Widget icon,
    required VoidCallback onTap,
    String? tooltip,
    bool showBadge = false,
  }) {
    Widget button = Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(10.spMin),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: _kSearchBarHeight.spMin,
          child: Center(child: icon),
        ),
      ),
    );

    if (showBadge) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            right: 4.spMin,
            top: 4.spMin,
            child: Container(
              width: 9.spMin,
              height: 9.spMin,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }

    return tooltip != null ? Tooltip(message: tooltip, child: button) : button;
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
            final state = ref.watch(singleCartProductSearchProvider);
            final notifier = ref.read(singleCartProductSearchProvider.notifier);
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
    final searchState = ref.watch(singleCartProductSearchProvider);
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
              padding: EdgeInsets.fromLTRB(
                16.spMin,
                12.spMin,
                16.spMin,
                6.spMin,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        hintText: 'Search products...',
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
                                        singleCartProductSearchProvider
                                            .notifier,
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
                                            searchState.selectedCategory !=
                                                null)
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
                              .read(singleCartProductSearchProvider.notifier)
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
                    // Barcode Scanner Button — mobile only (no camera scanner
                    // on desktop).
                    if (PlatformUtils.isMobile) ...[
                      SizedBox(width: 8.spMin),
                      _buildActionButton(
                        tooltip: 'Scan Barcode',
                        onTap:
                            () => _openBarcodeScanner(context, products, ref),
                        icon: AppIcon(
                          defaultIcon: Icons.qr_code_scanner,
                          win11IconPath: ImageAssets.win11QrCode,
                          size: 18.spMin,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
                            .read(singleCartProductSearchProvider.notifier)
                            .clearCategory(),
                onSelect:
                    (category) => ref
                        .read(singleCartProductSearchProvider.notifier)
                        .selectCategory(category),
              ),

            // Products Grid
            Expanded(
              child:
                  filteredProducts.isEmpty
                      ? (searchState.searchQuery.isNotEmpty ||
                              searchState.selectedBrand != null ||
                              searchState.selectedCategory != null
                          ? EmptyWidget1(
                            message:
                                searchState.searchQuery.isNotEmpty
                                    ? searchState.searchQuery
                                    : searchState.selectedBrand ??
                                        searchState.selectedCategory ??
                                        '',
                          )
                          : EmptyWidget1(message: "No products found"))
                      : LayoutBuilder(
                        builder: (context, constraints) {
                          // Size the cards off the section's OWN width (not the
                          // whole screen), so they stay the same size whether or
                          // not the cart panel is showing beside them. Capping
                          // the max card width lets the column count adapt.
                          //
                          // `maxCrossAxisExtent` is a pixel value → `.spMin`.
                          // `childAspectRatio` is a pure ratio → NOT scaled.
                          final double maxCardWidth =
                              isMobile ? 130.spMin : 170.spMin;
                          final double spacing = 8.spMin;
                          // Real column count of the grid (matches Flutter's
                          // SliverGridDelegateWithMaxCrossAxisExtent math) —
                          // needed for Up/Down navigation.
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
                              Widget card = ProductCard(
                                product: product,
                                isHighlighted: isKeyboardSelected,
                                onTap: () => _handleProductTap(product),
                                onMenuTapDown:
                                    (details) => _showProductMenu(
                                      context,
                                      product,
                                      details.globalPosition,
                                    ),
                              );
                              if (isKeyboardSelected) {
                                // One reusable key on the selected card so
                                // keyboard navigation can scroll it into view.
                                card = KeyedSubtree(
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

// Function wrapper for backwards compatibility
Widget buildProductsSectionWithSearch(WidgetRef ref) {
  return const ProductsSectionWithSearch();
}

/// Barcode Scanner Page
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  late MobileScannerController controller;
  bool _isScanning = true;
  String? _lastScanned;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      formats: [
        // Linear (1D) barcodes
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.itf,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        // 2D barcodes
        BarcodeFormat.qrCode,
        BarcodeFormat.dataMatrix,
        BarcodeFormat.pdf417,
        BarcodeFormat.aztec,
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    debugPrint('📷 Barcodes detected: ${barcodes.length}');

    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      debugPrint('📷 Barcode type: ${barcode.format}');
      debugPrint('📷 Barcode value: ${barcode.rawValue}');

      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _isScanning = false;
          _lastScanned = barcode.rawValue;
        });

        // Show scanned value briefly then return
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Navigator.pop(context, barcode.rawValue);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                final torchState = state.torchState;
                return Icon(
                  torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: controller, onDetect: _onDetect),
          // Scan overlay - wider for linear barcodes
          Center(
            child: Container(
              width: 300.w,
              height: 150.h,
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      _lastScanned != null ? Colors.green : AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // Show scanned value
          if (_lastScanned != null)
            Positioned(
              top: 100.h,
              left: 20.w,
              right: 20.w,
              child: Container(
                padding: EdgeInsets.all(16.h),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  children: [
                    Text(
                      'Scanned!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.spMin,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _lastScanned!,
                      style: TextStyle(color: Colors.white, fontSize: 14.spMin),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          // Instructions
          Positioned(
            bottom: 100.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _lastScanned != null
                      ? 'Barcode found!'
                      : 'Align barcode within the box',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.spMin,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
