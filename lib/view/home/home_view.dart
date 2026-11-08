import 'package:desktopapp/res/components/app_bar_widget.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../res/assets/image_assets.dart';
import '../../models/items_model.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/empty_widget.dart';
import '../../res/components/text_field_widget.dart';
import '../../utils/platform_utils.dart';
import '../../view_models/providers/home_page_provider.dart';
import '../../view_models/providers/sales_provider.dart';
import '../../view_models/providers/settings_provider.dart';
import '../../view_models/services/keyboard/app_keyboard_service.dart';
import '../add_product/add_product_view.dart';
import '../main/main_view.dart';
import '../sales/widgets/barcode_scan_flow.dart';
import '../shopping_list/shopping_list_view.dart';
import 'rapper.dart';
import 'section_products_view.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/beands_widget.dart';
import 'widgets/cat_widget.dart';
import 'widgets/header_wiget.dart';
import 'widgets/products_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  final VoidCallback openDrawer;

  const HomePage({super.key, required this.openDrawer});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends ConsumerState<HomePage> {
  /// Desktop shortcut scope: handled by the window-level keyboard dispatcher
  /// (see [AppKeyboardScope]) while Home is the visible page — focus-independent.
  late final AppKeyboardScope _keys = AppKeyboardScope('home', _handleKey);

  /// Home page product/service search. Non-empty = show a flat result grid
  /// (items + services) instead of the normal home sections.
  final TextEditingController _homeSearchController = TextEditingController();
  String _homeSearchQuery = '';

  /// Scan button in the app bar (mobile): open the camera scanner, collect
  /// the scanned items, and on "Add to Cart" commit them into the cart and
  /// jump to the Sales page so the user is already where the sale happens.
  Future<void> _scanProduct() async {
    final products = await ref.read(productsFutureProvider.future);
    if (!mounted) return;
    await scanAndFillCart(
      context: context,
      products: products,
      addToCart: (product, qty, force) {
        final notifier = ref.read(salesProvider.notifier);
        for (var i = 0; i < qty; i++) {
          notifier.addToCart(product, force: force);
        }
      },
      // Land on the Sales page — the items are already in the cart there.
      onAdded:
          () =>
              ref.read(selectedIndexProvider.notifier).state = kSalesIndex,
      // "Complete Purchase" on the scanner: jump to the sales tab and let
      // the sale view open its checkout with the just-committed items
      // (one-shot pendingCheckout flag).
      onCheckoutRequested: () {
        ref.read(pendingCheckoutProvider.notifier).state = true;
        ref.read(selectedIndexProvider.notifier).state = kSalesIndex;
      },
    );
  }

  /// Opens the add-item form (product or service) and refreshes the home
  /// list afterwards. Shared by the desktop FABs and the mobile buttons.
  void _openAddItem({required bool isService}) {
    // Capture notifier before async gap to avoid "ref" after unmount
    final notifier = ref.read(homePageProvider.notifier);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(isService: isService),
      ),
    ).then((value) {
      notifier.refreshProducts();
    });
  }

  /// Opens the shopping list. Shared by the desktop FAB and mobile button.
  void _openShoppingList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingListView()),
    );
  }

  @override
  void initState() {
    super.initState();
    AppKeyboardScope.register(_keys);
  }

  @override
  void dispose() {
    AppKeyboardScope.unregister(_keys);
    _homeSearchController.dispose();
    super.dispose();
  }

  /// Filter all items + services for the home search bar. Searches name,
  /// description, barcode, brand and category, case-insensitive.
  List<Product> _filteredCatalogue(List<Product> products, String query) {
    final q = query.toLowerCase();
    return products.where((p) {
      final haystack =
          [
            p.name,
            p.description ?? '',
            p.barcode ?? '',
            p.brand ?? '',
            p.category ?? '',
          ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  // Ctrl+N: New item (navigate to add product screen).
  // Ctrl+S: Save current item.
  // Ctrl+P: Print (following existing pattern in other desktop views).
  bool _handleKey(KeyEvent event) {
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyN, ctrl: true)) {
      _newItem();
      return true;
    }
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyS, ctrl: true)) {
      _saveItem();
      return true;
    }
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyP, ctrl: true)) {
      _printCurrentBill();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homePageProvider);
    final showShoppingList = ref.watch(
      settingsProvider.select((s) => s.showShoppingListModule),
    );

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        context: context,
        // Home is the nav hub on mobile: show the hamburger to open the drawer.
        automaticallyImplyLeading: AppSizes.isMobile(context),
        backIcon: Icons.menu,
        winBackIcon: ImageAssets.win11Menu,
        leadingOnTap: widget.openDrawer,
        title: 'Home',
        actions:
            PlatformUtils.isMobile
                ? [
                  IconButton(
                    // Mobile: quick barcode scan from anywhere — lands on the
                    // Sales page with the product in the cart.
                    tooltip: 'Scan Barcode',
                    splashRadius: 20.r,
                    onPressed: _scanProduct,
                    icon: AppIcon(
                      win11IconPath: ImageAssets.win11QrCode,
                      defaultIcon: Icons.qr_code_scanner,
                      size: 22.spMin,
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
                    ),
                  ),
                ]
                : const [],
      ),
      // Mobile: the FAB actions live as inline buttons under the search bar
      // (see _buildMobileActionButtons); hide the floating column there.
      floatingActionButton:
          AppSizes.isMobile(context)
              ? null
              : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'productFab',
            onPressed: () => _openAddItem(isService: false),
            icon: AppIcon(
              win11IconPath: ImageAssets.win11OpenBox,
              defaultIcon: Icons.inventory_2,
            ),
            label: Text(
              'Add Product',
              style: TextStyle(fontSize: 13.spMin, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(height: 12.spMin),
          FloatingActionButton.extended(
            heroTag: 'serviceFab',
            onPressed: () => _openAddItem(isService: true),
            icon: AppIcon(
              win11IconPath: ImageAssets.win11Services,
              defaultIcon: Icons.build,
            ),
            label: Text(
              'Add Services',
              style: TextStyle(fontSize: 13.spMin, fontWeight: FontWeight.w600),
            ),
          ),
          if (showShoppingList) ...[
            SizedBox(height: 12.spMin),
            FloatingActionButton.extended(
              heroTag: 'shoppingListFab',
              onPressed: _openShoppingList,
              icon: AppIcon(
                defaultIcon: Icons.shopping_bag,
                win11IconPath: ImageAssets.win11List,
              ),
              label: Text(
                'Shopping List',
                style: TextStyle(
                  fontSize: 13.spMin,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      body:
          homeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : homeState.error != null
              ? Center(child: Text('Error: ${homeState.error}'))
              : homeState.products.isEmpty
              ? Center(
                child: EmptyWidget1(message: "No products available"),
                // Text('No products available')
              )
              : ResponsiveWrapper(
                mobile: _buildSectionedView(context, ref),
                tablet: _buildSectionedView(context, ref),
                desktop: _buildSectionedView(context, ref),
              ),
    );
  }

  /// Opens the add item form (Ctrl+N / New item shortcut).
  void _newItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(isService: false),
      ),
    ).then((value) {
      if (mounted) {
        ref.read(homePageProvider.notifier).refreshProducts();
      }
    });
  }

  /// Saves the current/item being edited.
  /// From the home screen, saving navigates to the add product form.
  void _saveItem() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    ).then((value) {
      if (mounted) {
        ref.read(homePageProvider.notifier).refreshProducts();
      }
    });
  }

  Future<void> _printCurrentBill() async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ShoppingListView()),
      );
    }
  }

  Widget _buildSectionedView(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homePageProvider);
    final settings = ref.watch(settingsProvider);

    // Build sections based on order
    final sections = <Widget>[];

    for (final sectionKey in settings.sectionOrder) {
      switch (sectionKey) {
        case 'banner':
          if (settings.showBannerSection &&
              settings.bannerImagePaths.isNotEmpty) {
            sections.addAll([
              BannerCarousel(
                imagePaths: settings.bannerImagePaths,
                autoScroll: settings.bannerAutoScroll,
                scrollDuration: settings.bannerScrollDuration,
              ),
              SizedBox(height: settings.sectionSpacing.h),
            ]);
          }
          break;

        case 'brands':
          if (settings.showBrandsSection &&
              !homeState.brandsLoading &&
              homeState.brands.isNotEmpty) {
            sections.addAll([
              buildSectionHeader(
                'Shop by Brands',
                Icons.branding_watermark,
                ImageAssets.win11Brand,
                AppColors.primary,
              ),
              SizedBox(height: 12.h),
              buildBrandsCarousel(context, homeState.brands, ref),
              SizedBox(height: settings.sectionSpacing.h),
            ]);
          }
          break;

        case 'categories':
          if (settings.showCategoriesSection &&
              !homeState.categoriesLoading &&
              homeState.categories.isNotEmpty) {
            sections.addAll([
              buildSectionHeader(
                'Categories',
                Icons.category,
                ImageAssets.win11Category,
                Colors.purple,
              ),
              SizedBox(height: 12.h),
              buildCategoriesCarousel(context, homeState.categories, ref),
              SizedBox(height: settings.sectionSpacing.h),
            ]);
          }
          break;

        case 'topSelling':
          if (settings.showTopSellingSection &&
              homeState.topSellingProducts.isNotEmpty) {
            final products =
                homeState.topSellingProducts
                    .take(settings.topSellingProductsCount)
                    .toList();
            sections.addAll([
              buildSectionHeader(
                'Top Selling Products & Services',
                Icons.trending_up,
                ImageAssets.win11Increase,
                Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopSellingProductsView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              buildProductGrid(context, products, brands: homeState.brands),
              SizedBox(height: settings.sectionSpacing.h),
            ]);
          }
          break;

        case 'latestItems':
          if (settings.showLatestItemsSection &&
              homeState.latestItems.isNotEmpty) {
            final products =
                homeState.latestItems.take(settings.latestItemsCount).toList();
            sections.addAll([
              buildSectionHeader(
                'Latest Added Items',
                Icons.new_releases,
                ImageAssets.win11Nuw,
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LatestItemsView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              buildProductGrid(context, products, brands: homeState.brands),
              SizedBox(height: settings.sectionSpacing.h),
            ]);
          }
          break;

        case 'latestServices':
          if (settings.showLatestServicesSection &&
              homeState.latestServices.isNotEmpty) {
            final products =
                homeState.latestServices
                    .take(settings.latestServicesCount)
                    .toList();
            sections.addAll([
              buildSectionHeader(
                'Latest Services',
                Icons.room_service,
                ImageAssets.win11Services,
                Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LatestServicesView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              buildProductGrid(context, products, brands: homeState.brands),
              SizedBox(height: settings.sectionSpacing.h),
            ]);
          }
          break;

        case 'lowStock':
          if (settings.showLowStockSection &&
              homeState.lowStockItems.isNotEmpty) {
            final products =
                homeState.lowStockItems
                    .take(settings.lowStockItemsCount)
                    .toList();
            sections.addAll([
              buildSectionHeader(
                'Low Stock Items',
                Icons.warning_amber_rounded,
                ImageAssets.win11LowRisk,
                Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LowStockItemsView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              buildProductGrid(context, products, brands: homeState.brands),
              SizedBox(height: 24.h),
            ]);
          }
          break;
      }
    }

    // ---------- Home search bar (always the first block on the page) ----------
    final query = _homeSearchQuery.trim();
    final searching = query.isNotEmpty;

    final searchBar = CustomTextField(
      hintText: 'Search products or services...',
      controller: _homeSearchController,
      prefixIcon: Icon(
        Icons.search,
        size: 20.spMin,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white70
                : AppColors.lIconColor,
      ),
      suffixIcon:
          query.isEmpty
              ? null
              : IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 18.spMin),
                onPressed: () {
                  _homeSearchController.clear();
                  setState(() => _homeSearchQuery = '');
                },
              ),
      onChange: (value) {
        setState(() => _homeSearchQuery = value ?? '');
        return value;
      },
    );

    Widget content;
    if (searching) {
      // Search mode: flat grid of every matching item + service, replacing
      // the normal home sections.
      final productsAsync = ref.watch(productsFutureProvider);
      content = productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) => Center(
              child: Padding(
                padding: EdgeInsets.all(16.h),
                child: Text(
                  'Search failed: $error',
                  maxLines: 3,
                  style: TextStyle(fontSize: 13.spMin),
                ),
              ),
            ),
        data: (products) {
          final results = _filteredCatalogue(products, query);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildSectionHeader(
                'Search Results (${results.length})',
                Icons.search,
                ImageAssets.win11OpenBox,
                AppColors.primary,
              ),
              SizedBox(height: 12.h),
              if (results.isEmpty)
                EmptyWidget1(
                  message: 'No products or services found for "$query"',
                )
              else
                buildProductGrid(
                  context,
                  results,
                  brands: homeState.brands,
                  singleTapOpensDetails: true,
                ),
            ],
          );
        },
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.md.h,
        vertical: AppSizes.md.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchBar,
          if (AppSizes.isMobile(context)) ...[
            SizedBox(height: 10.h),
            _buildMobileActionButtons(),
          ],
          SizedBox(height: AppSizes.md.h),
          content,
        ],
      ),
    );
  }

  /// Mobile-only action buttons shown right under the home search bar — the
  /// old floating action buttons (Add Product / Add Services / Shopping List)
  /// re-imagined as inline buttons, two per row, plus the barcode scan button
  /// (same action as the app-bar scan icon).
  Widget _buildMobileActionButtons() {
    final showShoppingList = ref.watch(
      settingsProvider.select((s) => s.showShoppingListModule),
    );

    Widget actionButton({
      required String label,
      required String? win11IconPath,
      required IconData defaultIcon,
      required VoidCallback onTap,
    }) {
      return SizedBox(
        height: 42.spMin,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(
                win11IconPath: win11IconPath,
                defaultIcon: defaultIcon,
                color: Colors.white,
                size: 18.spMin,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13.spMin,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final buttons = <Widget>[
      // Scan: mobile only — matches the app-bar scan icon.
      actionButton(
        label: 'Scan',
        win11IconPath: ImageAssets.win11QrCode,
        defaultIcon: Icons.qr_code_scanner,
        onTap: _scanProduct,
      ),
      actionButton(
        label: 'Add Product',
        win11IconPath: ImageAssets.win11OpenBox,
        defaultIcon: Icons.inventory_2,
        onTap: () => _openAddItem(isService: false),
      ),
      actionButton(
        label: 'Add Services',
        win11IconPath: ImageAssets.win11Services,
        defaultIcon: Icons.build,
        onTap: () => _openAddItem(isService: true),
      ),
      if (showShoppingList)
        actionButton(
          label: 'List',
          win11IconPath: ImageAssets.win11List,
          defaultIcon: Icons.shopping_bag,
          onTap: _openShoppingList,
        ),
    ];

    // Two buttons per row.
    final rows = <Widget>[];
    for (var i = 0; i < buttons.length; i += 2) {
      final second = i + 1 < buttons.length ? buttons[i + 1] : const SizedBox();
      rows.add(
        Row(
          children: [
            Expanded(child: buttons[i]),
            SizedBox(width: 8.w),
            Expanded(child: second),
          ],
        ),
      );
      if (i + 2 < buttons.length) {
        rows.add(SizedBox(height: 8.h));
      }
    }

    return Column(children: rows);
  }
}
