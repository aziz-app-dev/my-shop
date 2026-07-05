import '../../models/items_model.dart';
import '../../models/brand_model.dart';
import '../../models/category_model.dart';

class HomePageState {
  final List<Product> products;
  final List<Product> topSellingProducts;
  final List<Product> latestItems;
  final List<Product> latestServices;
  final List<Product> lowStockItems;
  final List<Brand> brands;
  final List<Category> categories;
  final bool isLoading;
  final bool brandsLoading;
  final bool categoriesLoading;
  final String? error;

  const HomePageState({
    this.products = const [],
    this.topSellingProducts = const [],
    this.latestItems = const [],
    this.latestServices = const [],
    this.lowStockItems = const [],
    this.brands = const [],
    this.categories = const [],
    this.isLoading = false,
    this.brandsLoading = true,
    this.categoriesLoading = true,
    this.error,
  });

  HomePageState copyWith({
    List<Product>? products,
    List<Product>? topSellingProducts,
    List<Product>? latestItems,
    List<Product>? latestServices,
    List<Product>? lowStockItems,
    List<Brand>? brands,
    List<Category>? categories,
    bool? isLoading,
    bool? brandsLoading,
    bool? categoriesLoading,
    String? error,
  }) {
    return HomePageState(
      products: products ?? this.products,
      topSellingProducts: topSellingProducts ?? this.topSellingProducts,
      latestItems: latestItems ?? this.latestItems,
      latestServices: latestServices ?? this.latestServices,
      lowStockItems: lowStockItems ?? this.lowStockItems,
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      brandsLoading: brandsLoading ?? this.brandsLoading,
      categoriesLoading: categoriesLoading ?? this.categoriesLoading,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomePageState &&
        other.products == products &&
        other.topSellingProducts == topSellingProducts &&
        other.latestItems == latestItems &&
        other.latestServices == latestServices &&
        other.lowStockItems == lowStockItems &&
        other.brands == brands &&
        other.categories == categories &&
        other.isLoading == isLoading &&
        other.brandsLoading == brandsLoading &&
        other.categoriesLoading == categoriesLoading &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(
    products,
    topSellingProducts,
    latestItems,
    latestServices,
    lowStockItems,
    brands,
    categories,
    isLoading,
    brandsLoading,
    categoriesLoading,
    error,
  );
}
