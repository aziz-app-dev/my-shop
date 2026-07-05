import 'package:desktopapp/res/components/app_bar_widget.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../res/assets/image_assets.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/empty_widget.dart';
import '../../view_models/providers/home_page_provider.dart';
import '../../view_models/providers/settings_provider.dart';
import '../add_product/slection_card_view.dart';
import '../shopping_list/shopping_list_view.dart';
import 'rapper.dart';
import 'section_products_view.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/beands_widget.dart';
import 'widgets/cat_widget.dart';
import 'widgets/header_wiget.dart';
import 'widgets/products_widget.dart';

class HomePage extends ConsumerWidget {
  final VoidCallback openDrawer;

  const HomePage({super.key, required this.openDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homePageProvider);
    final showShoppingList = ref.watch(
      settingsProvider.select((s) => s.showShoppingListModule),
    );

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        context: context,
        automaticallyImplyLeading: false,
        title: 'Home',
        actions: [
          // Padding(
          //   padding: EdgeInsets.only(right: 8.w),
          //   child: Row(
          //     spacing: 4.w,
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       AppButton().primaryButton(
          //         padding: EdgeInsets.symmetric(horizontal: 4.w),

          //         text: "Add Products",
          //         onPressed: () {
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder:
          //                   (context) => const ProductTypeSelectionScreen(),
          //             ),
          //           ).then((value) {
          //             ref.read(homePageProvider.notifier).refreshProducts();
          //           });
          //         },
          //         width: 100.h,
          //         height: 28.h,
          //         fontSize: 11.spMin,
          //       ),
          //       AppButton().primaryButton(
          //         padding: EdgeInsets.symmetric(horizontal: 4.h),
          //         text: "Shopping List",
          //         onPressed: () {
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (context) => const ShoppingListView(),
          //             ),
          //           );
          //         },
          //         width: 100.h,
          //         height: 28.h,
          //         fontSize: 11.spMin,
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'productFab',
            onPressed: () {
              // Capture notifier before async gap to avoid "ref" after unmount
              final notifier = ref.read(homePageProvider.notifier);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductTypeSelectionScreen(),
                ),
              ).then((value) {
                notifier.refreshProducts();
              });
            },
            child: AppIcon(
              win11IconPath: ImageAssets.win11OpenBox,
              defaultIcon: Icons.inventory_2,
            ),
          ),
          if (showShoppingList) ...[
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: 'shoppingListFab',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShoppingListView(),
                  ),
                );
              },
              child: AppIcon(
                defaultIcon: Icons.shopping_bag,
                win11IconPath: ImageAssets.win11List,
              ),
            ),
          ],
        ],
      ),
      body:
          homeState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : homeState.error != null
              ? Center(child: Text('Error: ${homeState.error}'))
              : homeState.products.isEmpty
              ? Center(
                child: EmptyWidget1(message: "No products available"),
                // Text('No products available')
              )
              : ResponsiveWrapper(
                mobile: _buildSectionedView(context, homeState, ref),
                tablet: _buildSectionedView(context, homeState, ref),
                desktop: _buildSectionedView(context, homeState, ref),
              ),
    );
  }

  Widget _buildSectionedView(
    BuildContext context,
    dynamic homeState,
    WidgetRef ref,
  ) {
    final settings = ref.watch(settingsProvider);

    // Build sections based on order
    final sections = <Widget>[];

    for (final sectionKey in settings.sectionOrder) {
      switch (sectionKey) {
        case 'banner':
          if (settings.showBannerSection &&
              settings.bannerImagePaths.isNotEmpty) {
            sections.addAll([
              BannerCarousel(
                imagePaths: settings.bannerImagePaths,
                autoScroll: settings.bannerAutoScroll,
                scrollDuration: settings.bannerScrollDuration,
              ),
              SizedBox(height: 24.h),
            ]);
          }
          break;

        case 'brands':
          if (settings.showBrandsSection &&
              !homeState.brandsLoading &&
              homeState.brands.isNotEmpty) {
            sections.addAll([
              buildSectionHeader(
                'Shop by Brands',
                Icons.branding_watermark,
                ImageAssets.win11Brand,
                AppColors.primary,
              ),
              SizedBox(height: 12.h),
              buildBrandsCarousel(context, homeState.brands, ref),
              SizedBox(height: 24.h),
            ]);
          }
          break;

        case 'categories':
          if (settings.showCategoriesSection &&
              !homeState.categoriesLoading &&
              homeState.categories.isNotEmpty) {
            sections.addAll([
              buildSectionHeader(
                'Categories',
                Icons.category,
                ImageAssets.win11Category,
                Colors.purple,
              ),
              SizedBox(height: 12.h),
              buildCategoriesCarousel(context, homeState.categories, ref),
              SizedBox(height: 24.h),
            ]);
          }
          break;

        case 'topSelling':
          if (settings.showTopSellingSection &&
              homeState.topSellingProducts.isNotEmpty) {
            final products =
                homeState.topSellingProducts
                    .take(settings.topSellingProductsCount)
                    .toList();
            sections.addAll([
              buildSectionHeader(
                'Top Selling Products & Services',
                Icons.trending_up,
                ImageAssets.win11Increase,
                Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopSellingProductsView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              buildProductGrid(context, products, brands: homeState.brands),
              SizedBox(height: 24.h),
            ]);
          }
          break;

        case 'latestItems':
          if (settings.showLatestItemsSection &&
              homeState.latestItems.isNotEmpty) {
            final products =
                homeState.latestItems.take(settings.latestItemsCount).toList();
            sections.addAll([
              buildSectionHeader(
                'Latest Added Items',
                Icons.new_releases,
                ImageAssets.win11Nuw,
                Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LatestItemsView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              buildProductGrid(context, products, brands: homeState.brands),
              SizedBox(height: 24.h),
            ]);
          }
          break;

        case 'latestServices':
          if (settings.showLatestServicesSection &&
              homeState.latestServices.isNotEmpty) {
            final products =
                homeState.latestServices
                    .take(settings.latestServicesCount)
                    .toList();
            sections.addAll([
              buildSectionHeader(
                'Latest Services',
                Icons.room_service,
                ImageAssets.win11Services,
                Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LatestServicesView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              buildProductGrid(context, products, brands: homeState.brands),
              SizedBox(height: 24.h),
            ]);
          }
          break;

        case 'lowStock':
          if (settings.showLowStockSection &&
              homeState.lowStockItems.isNotEmpty) {
            final products =
                homeState.lowStockItems
                    .take(settings.lowStockItemsCount)
                    .toList();
            sections.addAll([
              buildSectionHeader(
                'Low Stock Items',
                Icons.warning_amber_rounded,
                ImageAssets.win11LowRisk,
                Colors.red,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LowStockItemsView(),
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              buildProductGrid(context, products, brands: homeState.brands),
              SizedBox(height: 24.h),
            ]);
          }
          break;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.md.h,
        vertical: AppSizes.md.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

}
