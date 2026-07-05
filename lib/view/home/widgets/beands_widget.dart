import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/brand_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../brands/brand_products_view.dart';
import 'brand_card.dart';

Widget buildBrandsCarousel(
  BuildContext context,
  List<Brand> brands,
  WidgetRef ref,
) {
  return HomeCardGrid(
    itemCount: brands.length,
    itemBuilder: (context, index) {
      final brand = brands[index];
      return BrandCard(
        title: brand.name,
        imageUrl: brand.imageUrl,
        accentColor: AppColors.primary,
        fallbackIcon: Icons.branding_watermark,
        fallbackWin11Icon: ImageAssets.win11Brand,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BrandProductsView(brand: brand),
            ),
          );
        },
      );
    },
  );
}
