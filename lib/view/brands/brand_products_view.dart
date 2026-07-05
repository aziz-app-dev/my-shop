import 'dart:io';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/res/components/text_field_widget.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/brand_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/product_card.dart';
import '../../view_models/providers/brand_products_provider.dart';

class BrandProductsView extends ConsumerStatefulWidget {
  final Brand brand;

  const BrandProductsView({super.key, required this.brand});

  @override
  ConsumerState<BrandProductsView> createState() => _BrandProductsViewState();
}

class _BrandProductsViewState extends ConsumerState<BrandProductsView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.grey800 : AppColors.grey200;

    // Watch the brand products provider
    final brandProductsState = ref.watch(brandProductsProvider(widget.brand));
    final brandProductsNotifier = ref.read(
      brandProductsProvider(widget.brand).notifier,
    );

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: widget.brand.name,
        context: context,
      ),
      body:
          brandProductsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : brandProductsState.error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon(
                      defaultIcon: Icons.error_outline,
                      win11IconPath: ImageAssets.win11LowRisk,
                      size: 64,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error: ${brandProductsState.error}',
                      style: TextStyle(fontSize: 16.spMin, color: Colors.red),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () => brandProductsNotifier.refreshProducts(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : CustomScrollView(
                slivers: [
                  //! Brand Header
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(15.h),
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border(
                          bottom: BorderSide(
                            color:
                                isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Brand Logo
                          if (widget.brand.imageUrl != null)
                            Container(
                              width: 55.h,
                              height: 55.h,
                              decoration: BoxDecoration(
                                // color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                                // border: Border.all(
                                //   color: AppColors.primary.withValues(alpha: 0.3),
                                //   width: 2,
                                // ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12.r),
                                child: Image.file(
                                  File(widget.brand.imageUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return AppIcon(
                                      defaultIcon: Icons.branding_watermark,
                                      win11IconPath: ImageAssets.win11Brand,
                                      size: 40.spMin,
                                      color: AppColors.primary,
                                    );
                                  },
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 55.h,
                              height: 55.h,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: AppIcon(
                                defaultIcon: Icons.branding_watermark,
                                win11IconPath: ImageAssets.win11Brand,
                                size: 40.spMin,
                                color: AppColors.primary,
                              ),
                            ),
                          SizedBox(height: 12.h),
                          mdText(text: widget.brand.name),
                          SizedBox(height: 4.h),
                          xsText(
                            text:
                                '${brandProductsState.allProducts.length} Products',
                          ),
                        ],
                      ),
                    ),
                  ),

                  //! Search Bar
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.md.w,
                        vertical: 2.h,
                      ),
                      child: CustomTextField(
                        hintText: "Search products...",
                        controller: _searchController,
                        onChange: (query) {
                          brandProductsNotifier.searchProducts(query ?? "");
                          return null;
                        },
                        prefixIcon: AppIcon(
                          defaultIcon: Icons.search,
                          win11IconPath: ImageAssets.win11Search,
                          color: AppColors.primary,
                          size: 20.spMin,
                        ),
                        filled: true,
                      ),
                    ),
                  ),

                  // Products Grid
                  brandProductsState.filteredProducts.isEmpty
                      ? SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIcon(
                                defaultIcon:
                                    brandProductsState.searchQuery.isNotEmpty
                                        ? Icons.search_off
                                        : Icons.inventory_2_outlined,
                                win11IconPath:
                                    brandProductsState.searchQuery.isNotEmpty
                                        ? ImageAssets.win11SearchClear
                                        : ImageAssets.win11Stock,
                                size: 64.spMin,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16.h),
                              smText(
                                text:
                                    brandProductsState.searchQuery.isNotEmpty
                                        ? 'No products found'
                                        : 'No products in this brand yet',
                              ),
                            ],
                          ),
                        ),
                      )
                      : SliverPadding(
                        padding: EdgeInsets.all(16.w),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            int crossAxisCount;
                            double childAspectRatio;

                            if (constraints.crossAxisExtent < 600) {
                              // Mobile
                              crossAxisCount = 2;
                              childAspectRatio = 0.75;
                            } else if (constraints.crossAxisExtent < 1100) {
                              // Tablet
                              crossAxisCount = 3;
                              childAspectRatio = 0.85;
                            } else {
                              // Desktop
                              crossAxisCount = 4;
                              childAspectRatio = 0.9;
                            }

                            return SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return ProductCard(
                                    product:
                                        brandProductsState
                                            .filteredProducts[index],
                                  );
                                },
                                childCount:
                                    brandProductsState.filteredProducts.length,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: childAspectRatio,
                                    crossAxisSpacing: 12.w,
                                    mainAxisSpacing: 12.h,
                                  ),
                            );
                          },
                        ),
                      ),
                ],
              ),
    );
  }
}
