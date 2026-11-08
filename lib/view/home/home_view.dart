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

  /// Scan button in the app bar (mobile): open the camera scanner and, on a
  /// match, add the product to the current cart and jump to the Sales page
  /// so the user is already where the sale happens.
  Future<void> _scanProduct() async {
    final products = await ref.read(productsFutureProvider.future);
    if (!mounted) return;
    await scanAndAddToCart(
      context: context,
      products: products,
      addToCart:
          (product) => ref.read(salesProvider.notifier).addToCart(product),
      // Land on the Sales page — the item is already in the cart there.
      onAdded:
          () =>
              ref.read(selectedIndexProvider.notifier).state = kSalesIndex,
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'productFab',
            onPressed: () {
              // Capture notifier before async gap to avoid "ref" after unmount
              final notifier = ref.read(homePageProvider.notifier);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => const AddProductScreen(isService: false),
                ),
              ).then((value) {
                notifier.refreshProducts();
              });
            },
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
            onPressed: () {
              // Capture notifier before async gap to avoid "ref" after unmount
              final notifier = ref.read(homePageProvider.notifier);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(isService: true),
                ),
              ).then((value) {
                notifier.refreshProducts();
              });
            },
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShoppingListView(),
                  ),
                );
              },
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
        children: [searchBar, SizedBox(height: AppSizes.md.h), content],
      ),
    );
  }
}
