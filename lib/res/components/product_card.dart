// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../../models/items/items_model.dart';

// class ProductCard extends StatelessWidget {
//   final Product product;
//   final VoidCallback? onTap;

//   const ProductCard({super.key, required this.product, this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(4),
//         child: Padding(
//           padding: EdgeInsets.all(6.h),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: Center(
//                   child: Icon(
//                     Icons.shopping_bag,
//                     size: 20.spMin,
//                     color: Theme.of(context).primaryColor,
//                   ),
//                 ),
//               ),
//               SizedBox(height: 4.h),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     product.name,
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 14.spMin,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   Text(
//                     'Rs.${product.price.toStringAsFixed(0)}',
//                     style: TextStyle(fontSize: 12.spMin, color: Colors.green),
//                   ),
//                 ],
//               ),
//               Text(
//                 'Stock: ${product.stock}',
//                 style: TextStyle(
//                   fontSize: 10.spMin,
//                   color: product.stock <= 5 ? Colors.red : Colors.grey,
//                 ),
//               ),
//               // Row(
//               //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               //   children: [
//               //     Text(
//               //       'Stock: ${product.stock}',
//               //       style: TextStyle(fontSize: 10.spMin, color: Colors.grey),
//               //     ),
//               //     const Spacer(),
//               //     if (product.stock <= 5)
//               //       Expanded(
//               //         child: Text(
//               //           'Low stock!',
//               //           style: TextStyle(fontSize: 10.spMin, color: Colors.red),
//               //           overflow: TextOverflow.ellipsis,
//               //         ),
//               //       ),
//               //   ],
//               // ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/items_model.dart';
import '../../models/brand_model.dart';
import '../../utils/app_sizes.dart';
import '../../view/product_details/product_details_view.dart';
import 'app_flushbar.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  /// Secondary tap (right-click on desktop). Used by the home page to show a
  /// "Details / Add to Cart" context menu. Null everywhere else, so other
  /// screens keep their existing behaviour.
  final GestureTapDownCallback? onSecondaryTapDown;

  /// Optional pre-loaded brand list. When provided, the brand badge is
  /// resolved synchronously with no database read. Callers that don't pass
  /// it simply render without a badge (avoids a per-card DB query).
  final List<Brand>? brands;

  /// Optional dropdown-menu button (shown top-right on the image). When set,
  /// a small caret button is drawn; tapping it opens the caller's action menu
  /// (Sale in cart / Details / Stock) without disturbing the card's own tap.
  final GestureTapDownCallback? onMenuTapDown;

  /// Optional long-press handler — in the sales grid on mobile, the
  /// 3-option menu opens on a long press. The card resolves its own box and
  /// passes the menu's anchor position (top-right, next to the caret button)
  /// as the argument.
  final void Function(Offset globalPosition)? onLongPress;

  /// True while the card is the keyboard-selected item (Tab / arrow walking
  /// in the sales grid). Draws an accent border so the user can see which
  /// item Enter will send to the cart.
  final bool? isHighlighted;

  const ProductCard({
    super.key,
    required this.product,
    this.onDoubleTap,
    this.onTap,
    this.onSecondaryTapDown,
    this.brands,
    this.onMenuTapDown,
    this.onLongPress,
    this.isHighlighted,
  });

  /// True when the item is a physical product at or below its reorder level
  /// (defaults to 5 when no explicit level is set). Services never alert.
  bool get isLowStock {
    if (product.isService) return false;
    final stock = product.stock;
    if (stock == null) return false;
    final threshold = product.reorderLevel ?? 5;
    return stock <= threshold;
  }

  Brand? get _brand {
    if (brands == null || product.brand == null || product.brand!.isEmpty) {
      return null;
    }
    for (final b in brands!) {
      if (b.name == product.brand) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final brand = _brand;

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          color:
              (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.dCardColor
                  : AppColors.lCardColor),
          border:
              (isHighlighted ?? false)
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
          borderRadius: BorderRadius.all(
            Radius.circular(AppSizes.borderRadiusSm.r),
          ),
        ),
        child: InkWell(
          onDoubleTap:
              onDoubleTap ??
              () async {
                final result = await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ProductDetailsScreen(product: product),
                  ),
                );
                if (result is Map &&
                    result['success'] == true &&
                    context.mounted) {
                  AppFlushbar.success(
                    context,
                    message:
                        result['message'] ?? 'Product updated successfully!',
                    duration: const Duration(seconds: 2),
                  );
                }
              },
          onTap: onTap,
          onSecondaryTapDown: onSecondaryTapDown,
          // InkWell has no positioned long-press; anchor the menu at the
          // caret button's spot (top-right of the card).
          onLongPress:
              onLongPress == null
                  ? null
                  : () {
                    final box = context.findRenderObject() as RenderBox;
                    final anchor = box.localToGlobal(
                      Offset(box.size.width - 40.h, 6.h),
                    );
                    onLongPress!(anchor);
                  },
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SizedBox(
                      height: 200.h,
                      child: Center(
                        child:
                            product.imageUrl != null &&
                                    product.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.borderRadiusSm.r,
                                  ),
                                  child: Image.file(
                                    File(product.imageUrl!),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    cacheWidth: 400,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                          Icons.broken_image,
                                          size: 40.spMin,
                                          color: Colors.grey,
                                        ),
                                  ),
                                )
                                : Icon(
                                  Icons.shopping_bag,
                                  size: 35.spMin,
                                  color: Theme.of(context).primaryColor,
                                ),
                      ),
                    ),
                    // Dropdown menu button (top-right): Sale in cart /
                    // Details / Stock. Independent of the card tap itself.
                    if (onMenuTapDown != null)
                      Positioned(
                        top: 6.h,
                        right: 6.w,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: onMenuTapDown,
                          child: Container(
                            width: 26.h,
                            height: 26.h,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              size: 20.spMin,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Brand Badge
                    if (brand != null &&
                        brand.imageUrl != null &&
                        brand.imageUrl!.isNotEmpty)
                      Positioned(
                        top: 6.h,
                        right: 6.w,
                        child: Container(
                          width: 32.h,
                          height: 32.h,
                          decoration: BoxDecoration(
                            // color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(3.h),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5.r),
                            child: Image.file(
                              File(brand.imageUrl!),
                              fit: BoxFit.contain,
                              cacheWidth: 64,
                              errorBuilder:
                                  (context, error, stackTrace) => Icon(
                                    Icons.branding_watermark,
                                    size: 18.spMin,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 2.h,
                  horizontal: 8.spMin,
                ),
                child: Column(
                  spacing: 2.h,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    smTextBold(text: product.name, maxLines: 1),
                    Row(
                      spacing: 2.w,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        smText(
                          text: 'Rs.${product.price.toStringAsFixed(0)}',
                          color: AppColors.primary,
                        ),
                        product.isService
                            ? Flexible(
                              child: customText(
                                size: 8.spMin,
                                text: 'Services',
                                color:
                                    (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.grey300
                                        : AppColors.grey600),
                              ),
                            )
                            : Flexible(
                              child: customText(
                                size: 8.spMin,
                                text:
                                    isLowStock
                                        ? 'Low: ${product.stock ?? 0}'
                                        : 'Stock: ${product.stock ?? 0}',
                                color:
                                    isLowStock
                                        ? Colors.red
                                        : (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.grey300
                                            : AppColors.grey600),
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
