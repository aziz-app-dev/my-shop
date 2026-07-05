import 'package:desktopapp/res/components/currency_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../models/items_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../view/widgets/cached_image_widget.dart';
import '../../../view_models/providers/product_details_provider.dart';
import '../../../view_models/states/product_details_state.dart';
import '../../home/widgets/products_widget.dart';

class MobileProductDetailsView extends ConsumerWidget {
  final Product product;

  const MobileProductDetailsView({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsState = ref.watch(productDetailsProvider(product));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 800;
        final double contentWidth = constraints.maxWidth - 48.spMin;
        final double imageWidth = isWide ? contentWidth * 0.38 : contentWidth;

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.spMin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Top: image + info =====
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: imageWidth.clamp(240.0, 380.0),
                      child: _buildImage(isDark),
                    ),
                    SizedBox(width: 32.spMin),
                    Expanded(child: _buildInfo(context, isDark, isWide)),
                  ],
                )
              else ...[
                _buildImage(isDark),
                SizedBox(height: 20.spMin),
                _buildInfo(context, isDark, isWide),
              ],

              SizedBox(height: 32.spMin),

              // ===== Performance =====
              if (!detailsState.isLoading) ...[
                Text(
                  'Performance',
                  style: TextStyle(
                    fontSize: 18.spMin,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 16.spMin),
                _buildPerformance(detailsState, isDark, isWide, contentWidth),
              ],

              // ===== Related products (kept) =====
              if (detailsState.relatedProducts.isNotEmpty) ...[
                SizedBox(height: 32.spMin),
                _buildRelatedProductsSection(detailsState, context, isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Image
  // ---------------------------------------------------------------------------
  Widget _buildImage(bool isDark) {
    return Hero(
      tag: 'product-${product.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.spMin),
        child: Container(
          color: isDark ? Colors.grey.shade900 : AppColors.grey100,
          child: AspectRatio(
            aspectRatio: 1,
            child: AppCachedImage(
              imageUrl: product.imageUrl,
              fit: BoxFit.cover,
              folder: 'products',
              errorWidget: Center(
                child: AppIcon(
                  win11IconPath:
                      product.isService
                          ? ImageAssets.win11Services
                          : ImageAssets.win11NoImage,
                  defaultIcon:
                      product.isService
                          ? Icons.room_service
                          : Icons.image_not_supported,
                  size: 56.spMin,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Info column (badges, name, price, description, meta grid)
  // ---------------------------------------------------------------------------
  Widget _buildInfo(BuildContext context, bool isDark, bool isWide) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final dividerColor = isDark ? AppColors.grey800 : AppColors.grey200;

    final hasBrand =
        product.brand != null &&
        product.brand!.isNotEmpty &&
        product.brand != 'No Brand';
    final hasCategory =
        product.category != null && product.category!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badges
        Wrap(
          spacing: 8.spMin,
          runSpacing: 8.spMin,
          children: [
            _badge(
              product.isService ? 'Service' : (product.condition ?? 'New'),
              filled: true,
              isDark: isDark,
            ),
            if (hasBrand)
              _badge(product.brand!, filled: false, isDark: isDark),
            if (hasCategory)
              _badge(product.category!, filled: false, isDark: isDark),
          ],
        ),
        SizedBox(height: 16.spMin),

        // Name
        Text(
          product.name,
          style: TextStyle(
            fontSize: 22.spMin,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: textColor,
          ),
        ),
        SizedBox(height: 10.spMin),

        // Price
        Currency(
          amount: product.price,
          size: 24.spMin,
          fractionDigits: 2,
          color: textColor,
        ),
        SizedBox(height: 20.spMin),

        Divider(color: dividerColor, height: 1),
        SizedBox(height: 16.spMin),

        // Description
        if (product.description != null &&
            product.description!.isNotEmpty) ...[
          Text(
            'Description',
            style: TextStyle(
              fontSize: 13.spMin,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
          SizedBox(height: 8.spMin),
          Text(
            product.description!,
            style: TextStyle(
              fontSize: 13.spMin,
              height: 1.5,
              color: isDark ? AppColors.grey300 : AppColors.grey700,
            ),
          ),
          SizedBox(height: 16.spMin),
          Divider(color: dividerColor, height: 1),
          SizedBox(height: 16.spMin),
        ],

        // Meta grid
        _buildMetaGrid(isDark, isWide),
      ],
    );
  }

  Widget _badge(String text, {required bool filled, required bool isDark}) {
    final Color fillColor = filled
        ? (isDark ? Colors.white : Colors.black)
        : Colors.transparent;
    final Color textColor = filled
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : AppColors.grey800);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.spMin, vertical: 6.spMin),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(8.spMin),
        border: filled
            ? null
            : Border.all(
                color: isDark ? AppColors.grey700 : AppColors.grey300,
              ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.spMin,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMetaGrid(bool isDark, bool isWide) {
    final items = <Widget>[
      _metaItem(
        icon: Icons.sell_outlined,
        win11: ImageAssets.win11Brand,
        label: 'Brand',
        value: product.brand ?? 'No Brand',
        isDark: isDark,
      ),
      _metaItem(
        icon: Icons.category_outlined,
        win11: null,
        label: 'Category',
        value:
            (product.category != null && product.category!.isNotEmpty)
                ? product.category!
                : '—',
        isDark: isDark,
      ),
      if (!product.isService) ...[
        _metaItem(
          icon: Icons.verified_outlined,
          win11: ImageAssets.win11Nuw,
          label: 'Condition',
          value: product.condition ?? 'New',
          isDark: isDark,
        ),
        _metaItem(
          icon: Icons.inventory_2_outlined,
          win11: ImageAssets.win11OpenBox,
          label: 'In stock',
          value: product.stock?.toString() ?? '—',
          isDark: isDark,
        ),
      ],
    ];

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: EdgeInsets.only(bottom: 14.spMin),
              child: item,
            ),
        ],
      );
    }

    // Two columns on wide screens.
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: 16.spMin),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: items[i]),
              SizedBox(width: 24.spMin),
              Expanded(
                child:
                    (i + 1) < items.length ? items[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _metaItem({
    required IconData icon,
    required String? win11,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon(
          defaultIcon: icon,
          win11IconPath: win11,
          size: 18.spMin,
          color: AppColors.grey500,
        ),
        SizedBox(width: 8.spMin),
        Expanded(
          child: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label:  ',
                  style: TextStyle(
                    fontSize: 13.spMin,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 13.spMin,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Performance stat cards
  // ---------------------------------------------------------------------------
  Widget _buildPerformance(
    ProductDetailsState state,
    bool isDark,
    bool isWide,
    double contentWidth,
  ) {
    final numberFmt = NumberFormat.decimalPattern();

    final cards = <Widget>[
      _statCard(
        label: 'Total Customers',
        value: _statValue(numberFmt.format(state.customerCount), isDark),
        icon: Icons.people_outline,
        win11: ImageAssets.win11TestAccount,
        isDark: isDark,
      ),
      _statCard(
        label: 'Total Sold',
        value: _statValue(numberFmt.format(state.totalSold), isDark),
        icon: Icons.shopping_cart_outlined,
        win11: ImageAssets.win11Checkout,
        isDark: isDark,
      ),
      _statCard(
        label: 'Total Revenue',
        value: Currency(
          amount: state.totalRevenue,
          size: 15.spMin,
          fractionDigits: 2,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        icon: Icons.payments_outlined,
        win11: ImageAssets.win11DollarBag,
        isDark: isDark,
      ),
      if (!product.isService)
        _statCard(
          label: 'Total Stock',
          value: _statValue(numberFmt.format(product.stock ?? 0), isDark),
          icon: Icons.inventory_2_outlined,
          win11: ImageAssets.win11OpenBox,
          isDark: isDark,
        ),
    ];

    if (isWide) {
      final children = <Widget>[];
      for (var i = 0; i < cards.length; i++) {
        children.add(Expanded(child: cards[i]));
        if (i != cards.length - 1) children.add(SizedBox(width: 12.spMin));
      }
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    }

    // 2-up grid on narrow screens.
    final double cardWidth = (contentWidth - 12.spMin) / 2;
    return Wrap(
      spacing: 12.spMin,
      runSpacing: 12.spMin,
      children: [for (final c in cards) SizedBox(width: cardWidth, child: c)],
    );
  }

  Widget _statValue(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16.spMin,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _statCard({
    required String label,
    required Widget value,
    required IconData icon,
    required String? win11,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(16.spMin),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(14.spMin),
        border: Border.all(
          color: isDark ? AppColors.grey800 : AppColors.grey200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42.spMin,
            height: 42.spMin,
            decoration: BoxDecoration(
              color: isDark ? AppColors.grey800 : AppColors.grey100,
              borderRadius: BorderRadius.circular(10.spMin),
            ),
            child: Center(
              child: AppIcon(
                defaultIcon: icon,
                win11IconPath: win11,
                size: 20.spMin,
                color: isDark ? Colors.white70 : AppColors.grey700,
              ),
            ),
          ),
          SizedBox(width: 12.spMin),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.spMin,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: isDark ? AppColors.grey400 : AppColors.grey600,
                  ),
                ),
                SizedBox(height: 4.spMin),
                value,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Related products (retained from previous design)
  // ---------------------------------------------------------------------------
  Widget _buildRelatedProductsSection(
    ProductDetailsState state,
    BuildContext context,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.isService
              ? 'Top Services'
              : 'More from ${product.brand ?? "this brand"}',
          style: TextStyle(
            fontSize: 18.spMin,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 16.spMin),
        // Reuse the same card + responsive grid as the home page so the
        // related items match it exactly (equal width/height).
        buildProductGrid(context, state.relatedProducts),
      ],
    );
  }
}
