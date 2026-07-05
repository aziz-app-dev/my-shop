// ignore_for_file: file_names

import 'package:desktopapp/res/components/app_bar_widget.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/category_model.dart';
import '../../../models/items_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/product_card.dart';
import '../../../view_models/services/database/database_services.dart';

// Category Products View (similar to BrandProductsView)
class CategoryProductsView extends ConsumerWidget {
  final Category category;

  const CategoryProductsView({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBarWidget.customAppBar(title: category.name, context: context),
      body: FutureBuilder<List<Product>>(
        future: DatabaseService().getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products =
              snapshot.data
                  ?.where((p) => p.category == category.name)
                  .toList() ??
              [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(
                    win11IconPath: ImageAssets.win11Category,
                    defaultIcon: Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No products in this category',
                    style: TextStyle(fontSize: 16.spMin, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Responsive grid configuration
          int crossAxisCount;
          double childAspectRatio;

          if (AppSizes.isMobile(context)) {
            // Mobile
            crossAxisCount = 3;
            childAspectRatio = 0.99.spMin;
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
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.md.h,
              vertical: AppSizes.md.h,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return ProductCard(product: products[index]);
            },
          );
        },
      ),
    );
  }
}
