// Screen Management Section Widget
import 'package:desktopapp/res/assets/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../res/colors/app_color.dart';
import '../../../res/components/app_bar_widget.dart';
import '../../../utils/app_sizes.dart';
import '../../brands/brand_management_view.dart';
import '../../profile/category_management_view.dart';
import 'custom_tile.dart';

// Data Management Page
class DataManagementPage extends ConsumerWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Data Management',
        context: context,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.md.h,
          vertical: AppSizes.sm.h,
        ),
        children: [
          // Manage Brands
          Card(
            child: customTileWidget(
              context,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BrandManagementScreen(),
                  ),
                );
              },
              'Manage Brands',
              'Add, edit, or delete product brands',
              AppColors.primary,
              Icons.branding_watermark,
              ImageAssets.win11Brand,
            ),
          ),
          SizedBox(height: 12.h),
          // Manage Categories
          Card(
            child: customTileWidget(
              context,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryManagementScreen(),
                  ),
                );
              },
              'Manage Categories',
              'Add, edit, or delete product categories',
              AppColors.primary,
              Icons.category,
              ImageAssets.win11Category,
            ),
          ),
        ],
      ),
    );
  }
}
