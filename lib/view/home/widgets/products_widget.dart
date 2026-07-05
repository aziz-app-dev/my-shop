import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/items_model.dart';
import '../../../models/brand_model.dart';
import '../../../res/components/product_card.dart';

Widget buildProductGrid(
  BuildContext context,
  List<Product> products, {
  List<Brand>? brands,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      int crossAxisCount;
      double childAspectRatio;

      if (AppSizes.isMobile(context)) {
        // Mobile
        crossAxisCount = 3;
        childAspectRatio = 0.80.spMin;
      } else if (AppSizes.isTablet(context)) {
        // Tablet
        crossAxisCount = 5;
        childAspectRatio = 0.99.spMin;
      } else {
        // Desktop
        crossAxisCount = 7;
        childAspectRatio = 0.9.spMin;
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: childAspectRatio,
          crossAxisSpacing: 6.w,
          mainAxisSpacing: 15.h,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index], brands: brands);
        },
      );
    },
  );
}
