import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../models/brand_model.dart';
import '../../../models/items_model.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_flushbar.dart';
import '../../../res/components/product_card.dart';
import '../../../view_models/providers/multi_cart_provider.dart';
import '../../../view_models/providers/sales_provider.dart';
import '../../../view_models/providers/settings_provider.dart';
import '../../main/main_view.dart' show selectedIndexProvider;
import '../../product_details/product_details_view.dart';

/// The Sales tab's index in the main navigation page list (Home is 0, Sales 1).
const int _kSalesTabIndex = 1;

/// Home-page product card. Keeps the shared [ProductCard] behaviour (double-tap
/// opens details) and adds a right-click / secondary-tap context menu with
/// "Details" and "Add to Cart" — the latter drops the product into the sales
/// cart and switches to the Sales tab.
class HomeProductCard extends ConsumerWidget {
  final Product product;
  final List<Brand>? brands;

  const HomeProductCard({super.key, required this.product, this.brands});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProductCard(
      product: product,
      brands: brands,
      onSecondaryTapDown:
          (details) => _showContextMenu(context, ref, details.globalPosition),
    );
  }

  Future<void> _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: [
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
          value: 'cart',
          child: Row(
            children: [
              Icon(
                TablerIcons.shopping_cart_plus,
                size: 18.spMin,
                color: AppColors.primary,
              ),
              SizedBox(width: 10.spMin),
              Text('Add to Cart', style: TextStyle(fontSize: 13.spMin)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;
    if (selected == 'details') {
      await _openDetails(context);
    } else if (selected == 'cart') {
      _addToCartAndGo(context, ref);
    }
  }

  Future<void> _openDetails(BuildContext context) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
    if (result is Map && result['success'] == true && context.mounted) {
      AppFlushbar.success(
        context,
        message: result['message'] ?? 'Product updated successfully!',
        duration: const Duration(seconds: 2),
      );
    }
  }

  void _addToCartAndGo(BuildContext context, WidgetRef ref) {
    // Out-of-stock guard (services have no stock and are always sellable).
    if (!product.isService && product.stock != null && product.stock! <= 0) {
      AppFlushbar.warning(context, message: '${product.name} is out of stock');
      return;
    }

    final useMultiCart = ref.read(settingsProvider).useMultiCart;

    if (useMultiCart) {
      final multiCart = ref.read(multiCartProvider);
      final notifier = ref.read(multiCartProvider.notifier);
      final active = multiCart.activeCart;
      // Reuse the currently open cart only when it's still empty; otherwise
      // start a fresh cart so an in-progress sale isn't disturbed.
      if (active == null || active.cartItems.isNotEmpty) {
        notifier.createNewCart();
      }
      notifier.addToCart(product);
    } else {
      ref.read(salesProvider.notifier).addToCart(product);
    }

    // Land the user on the Sales tab so they see the cart.
    ref.read(selectedIndexProvider.notifier).state = _kSalesTabIndex;
    AppFlushbar.success(context, message: '${product.name} added to cart');
  }
}
