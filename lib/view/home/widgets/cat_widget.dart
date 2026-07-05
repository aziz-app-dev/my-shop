import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/category_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../view_models/providers/home_page_provider.dart';
import 'brand_card.dart';
import 'cat_items_View.dart';

Widget buildCategoriesCarousel(
  BuildContext context,
  List<Category> categories,
  WidgetRef ref,
) {
  return HomeCardGrid(
    itemCount: categories.length,
    itemBuilder: (context, index) {
      final category = categories[index];
      return BrandCard(
        title: category.name,
        imageUrl: category.imageUrl,
        accentColor: Colors.purple,
        fallbackIcon: Icons.category,
        fallbackWin11Icon: ImageAssets.win11Category,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryProductsView(category: category),
            ),
          );
          if (context.mounted) {
            ref.read(homePageProvider.notifier).refreshProducts();
          }
        },
      );
    },
  );
}
