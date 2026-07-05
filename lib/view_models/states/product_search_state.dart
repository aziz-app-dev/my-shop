class ProductSearchState {
  final String searchQuery;
  final String? selectedBrand;
  final String? selectedCategory;

  const ProductSearchState({
    this.searchQuery = '',
    this.selectedBrand,
    this.selectedCategory,
  });

  ProductSearchState copyWith({
    String? searchQuery,
    String? selectedBrand,
    String? selectedCategory,
    bool clearBrand = false,
    bool clearCategory = false,
  }) {
    return ProductSearchState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBrand: clearBrand ? null : (selectedBrand ?? this.selectedBrand),
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductSearchState &&
        other.searchQuery == searchQuery &&
        other.selectedBrand == selectedBrand &&
        other.selectedCategory == selectedCategory;
  }

  @override
  int get hashCode => Object.hash(searchQuery, selectedBrand, selectedCategory);
}
