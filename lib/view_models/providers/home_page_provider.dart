import '../states/home_page_state.dart';
import '../services/database/database_services.dart';
import '../../models/items_model.dart';
import '../../models/bills_model.dart';
import '../../models/brand_model.dart';
import '../../models/category_model.dart';
import 'package:riverpod/legacy.dart';

class HomePageNotifier extends StateNotifier<HomePageState> {
  final DatabaseService _dbService;

  HomePageNotifier(this._dbService)
    : super(const HomePageState(isLoading: true)) {
    loadHomeData();
  }

  /// Loads everything the home page needs in a single pass.
  ///
  /// Previously products were read from Hive three separate times (once each
  /// in loadProducts/loadBrands/loadCategories, all running concurrently),
  /// and each loader pushed its own state update. Now we read each box once,
  /// derive every section from the in-memory lists, and emit a single state
  /// update — which removes the startup lag and the redundant rebuilds.
  Future<void> loadHomeData() async {
    // Yield once so we never mutate state synchronously during the build
    // that first reads this (autoDispose) provider — doing so triggers a
    // "setState() called during build" error.
    await Future<void>.microtask(() {});
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Read each box exactly once, in parallel.
      final results = await Future.wait([
        _dbService.getProducts(),
        _dbService.getBills(),
        _dbService.getBrands(),
        _dbService.getCategories(),
      ]);

      final products = results[0] as List<Product>;
      final bills = results[1] as List<Bill>;
      final brands = results[2] as List<Brand>;
      final categories = results[3] as List<Category>;

      final derived = _deriveSections(products, bills, brands, categories);

      state = state.copyWith(
        products: products,
        topSellingProducts: derived.topSelling,
        latestItems: derived.latestItems,
        latestServices: derived.latestServices,
        lowStockItems: derived.lowStock,
        brands: derived.brands,
        categories: derived.categories,
        isLoading: false,
        brandsLoading: false,
        categoriesLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        brandsLoading: false,
        categoriesLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Computes every home-page section from already-loaded lists.
  _DerivedSections _deriveSections(
    List<Product> products,
    List<Bill> bills,
    List<Brand> allBrands,
    List<Category> allCategories,
  ) {
    // --- Sales counts for top-selling ---
    final Map<String, int> productSalesCount = {};
    for (final bill in bills) {
      for (final entry in bill.quantities.entries) {
        productSalesCount[entry.key] =
            (productSalesCount[entry.key] ?? 0) + entry.value;
      }
    }

    final topSelling = [...products]..sort((a, b) {
      final aSales = productSalesCount[a.id] ?? 0;
      final bSales = productSalesCount[b.id] ?? 0;
      return bSales.compareTo(aSales);
    });

    // --- Latest items / services / low stock (single iteration) ---
    final latestItems = <Product>[];
    final latestServices = <Product>[];
    final lowStockItems = <Product>[];
    final brandNamesWithProducts = <String>{};
    final categoryNamesWithProducts = <String>{};

    for (final p in products) {
      if (p.isService) {
        latestServices.add(p);
      } else {
        latestItems.add(p);
        if (p.stock != null && p.stock! < 10 && p.stock! > 0) {
          lowStockItems.add(p);
        }
      }
      if (p.brand != null && p.brand!.isNotEmpty) {
        brandNamesWithProducts.add(p.brand!);
      }
      if (p.category != null && p.category!.isNotEmpty) {
        categoryNamesWithProducts.add(p.category!);
      }
    }

    latestItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    latestServices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    lowStockItems.sort((a, b) => (a.stock ?? 0).compareTo(b.stock ?? 0));

    // --- Brands/categories that have products, deduped by name ---
    final seenBrandNames = <String>{};
    final filteredBrands = allBrands
        .where((b) => brandNamesWithProducts.contains(b.name))
        .where((b) => seenBrandNames.add(b.name))
        .toList();

    final seenCategoryNames = <String>{};
    final filteredCategories = allCategories
        .where((c) => categoryNamesWithProducts.contains(c.name))
        .where((c) => seenCategoryNames.add(c.name))
        .toList();

    return _DerivedSections(
      topSelling: topSelling.take(10).toList(),
      latestItems: latestItems.take(10).toList(),
      latestServices: latestServices.take(10).toList(),
      lowStock: lowStockItems,
      brands: filteredBrands,
      categories: filteredCategories,
    );
  }

  /// Reload everything (used after add/edit/category navigation).
  Future<void> refreshProducts() => loadHomeData();
}

class _DerivedSections {
  final List<Product> topSelling;
  final List<Product> latestItems;
  final List<Product> latestServices;
  final List<Product> lowStock;
  final List<Brand> brands;
  final List<Category> categories;

  const _DerivedSections({
    required this.topSelling,
    required this.latestItems,
    required this.latestServices,
    required this.lowStock,
    required this.brands,
    required this.categories,
  });
}

// Provider
final homePageProvider =
    StateNotifierProvider.autoDispose<HomePageNotifier, HomePageState>(
      (ref) => HomePageNotifier(DatabaseService()),
    );
