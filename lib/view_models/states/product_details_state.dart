import '../../models/items_model.dart';

class ProductDetailsState {
  final int customerCount;
  final int totalSold;
  final double totalRevenue;
  final bool isLoading;
  final String? error;
  final String? brandLogoUrl;
  final List<Product> relatedProducts;

  ProductDetailsState({
    this.customerCount = 0,
    this.totalSold = 0,
    this.totalRevenue = 0.0,
    this.isLoading = false,
    this.error,
    this.brandLogoUrl,
    this.relatedProducts = const [],
  });

  ProductDetailsState copyWith({
    int? customerCount,
    int? totalSold,
    double? totalRevenue,
    bool? isLoading,
    String? error,
    String? brandLogoUrl,
    List<Product>? relatedProducts,
  }) {
    return ProductDetailsState(
      customerCount: customerCount ?? this.customerCount,
      totalSold: totalSold ?? this.totalSold,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      brandLogoUrl: brandLogoUrl ?? this.brandLogoUrl,
      relatedProducts: relatedProducts ?? this.relatedProducts,
    );
  }
}
