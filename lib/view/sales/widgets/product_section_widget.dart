import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../view_models/providers/sales_provider.dart';
import '../../../res/components/product_card.dart';

Widget buildProductsSection(WidgetRef ref) {
  final productsAsync = ref.watch(productsFutureProvider);
  final bool isTablet =
      MediaQuery.of(ref.context).size.width >= 600 &&
      MediaQuery.of(ref.context).size.width < 1100;
  final bool isMobile = MediaQuery.of(ref.context).size.width < 600;

  return productsAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error:
        (error, stack) => Center(
          child: Text('Error: $error', style: TextStyle(fontSize: 16.spMin)),
        ),
    data: (products) {
      if (products.isEmpty) {
        return Center(
          child: Text(
            'No items available',
            style: TextStyle(fontSize: 16.spMin),
          ),
        );
      }

      final crossAxisCount = isMobile ? 3 : (isTablet ? 4 : 5);
      final padding = 4.w;

      return GridView.builder(
        padding: EdgeInsets.all(padding),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio:
              isMobile
                  ? 0.80.spMin
                  : isTablet
                  ? 0.90.spMin
                  : 0.80.spMin,
          crossAxisSpacing: padding,
          mainAxisSpacing: padding,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
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
                      (context) => Container(
                        decoration: BoxDecoration(
                          color:
                              (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.dBodyColor
                                  : AppColors.lBodyColor),
                          borderRadius: BorderRadius.all(
                            Radius.circular(AppSizes.borderRadiusMd),
                          ),
                        ),
                        child: AlertDialog(
                          backgroundColor:
                              (Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.dBodyColor
                                  : AppColors.lBodyColor),
                          title: mdTextBold(text: 'Out of Stock'),
                          content: smText(
                            text: '${product.name} is currently out of stock.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: smTextBold(text: "Ok"),
                            ),
                          ],
                        ),
                      ),
                );
              } else {
                ref.read(salesProvider.notifier).addToCart(product);
              }
            },
          );
        },
      );
    },
  );
}
