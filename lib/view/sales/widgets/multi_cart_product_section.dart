import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../models/items_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/text_field_widget.dart';
import '../../../utils/platform_utils.dart';
import '../../../view_models/providers/multi_cart_provider.dart';
import '../../../view_models/providers/sales_provider.dart';
import '../../../view_models/providers/product_search_provider.dart';
import '../../../res/components/product_card.dart';

/// Shared height for the search field and the action buttons next to it, so
/// they line up exactly across desktop / tablet / mobile.
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
    _searchController.dispose();
    super.dispose();
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
      MaterialPageRoute(
        builder: (context) => const _MultiCartBarcodeScannerPage(),
      ),
    );

    debugPrint('🔍 Multi-cart barcode scanned: $result');
    debugPrint('🔍 Total products to search: ${products.length}');

    // Debug: Print all products with their barcodes
    for (final p in products) {
      debugPrint('📦 Product: ${p.name}, Barcode: "${p.barcode ?? "NULL"}"');
    }

    if (!context.mounted) {
      debugPrint('❌ Context not mounted, returning');
      return;
    }
    debugPrint('✅ Context is mounted');

    // Show what was scanned for debugging
    if (result == null || result.isEmpty) {
      debugPrint('❌ Result is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan cancelled or no barcode detected'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    debugPrint('✅ Result is valid: $result');

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
        // Add to multi-cart
        debugPrint('🛒 Adding to multi-cart: ${product.name}');
        ref.read(multiCartProvider.notifier).addToCart(product);
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
                        prefixIcon: Icon(
                          TablerIcons.search,
                          size: 20.spMin,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white70
                                  : AppColors.lIconColor,
                        ),
                        suffixIcon:
                            searchState.searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: Icon(TablerIcons.x, size: 20.spMin),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(
                                          multiCartProductSearchProvider
                                              .notifier,
                                        )
                                        .clearSearch();
                                  },
                                )
                                : null,
                        onChange: (value) {
                          ref
                              .read(multiCartProductSearchProvider.notifier)
                              .updateSearchQuery(value!);
                          return null;
                        },
                      ),
                    ),
                    // Filter button — opens a popup to pick brand / category.
                    SizedBox(width: 8.spMin),
                    _buildActionButton(
                      tooltip: 'Filters',
                      showBadge:
                          searchState.selectedBrand != null ||
                          searchState.selectedCategory != null,
                      onTap:
                          () => _showFilterDialog(context, brands, categories),
                      icon: AppIcon(
                        defaultIcon: TablerIcons.filter,
                        size: 18.spMin,
                        color: Colors.white,
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

            // Category Filter Row (chips under the search bar)
            if (categories.isNotEmpty)
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
                          return GridView.builder(
                            padding: EdgeInsets.all(8.spMin),
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: maxCardWidth,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 8.spMin,
                              mainAxisSpacing: 8.spMin,
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return ProductCard(
                                product: product,
                                onTap: () {
                                  // Skip stock check for services (isService == true, stock == null)
                                  if (!product.isService &&
                                      product.stock != null &&
                                      product.stock! <= 0) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: mdTextBold(
                                              text: 'Out of Stock',
                                            ),
                                            content: smText(
                                              text:
                                                  '${product.name} is currently out of stock.',
                                              maxLines: 3,
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(context),
                                                child: Text(
                                                  'OK',
                                                  style: TextStyle(
                                                    fontSize: 14.spMin,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                    );
                                  } else {
                                    // Use multi-cart provider to add to active cart
                                    ref
                                        .read(multiCartProvider.notifier)
                                        .addToCart(product);
                                  }
                                },
                              );
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

/// Barcode Scanner Page for Multi Cart
class _MultiCartBarcodeScannerPage extends StatefulWidget {
  const _MultiCartBarcodeScannerPage();

  @override
  State<_MultiCartBarcodeScannerPage> createState() =>
      _MultiCartBarcodeScannerPageState();
}

class _MultiCartBarcodeScannerPageState
    extends State<_MultiCartBarcodeScannerPage> {
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
    debugPrint('📷 Multi-cart barcodes detected: ${barcodes.length}');

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
