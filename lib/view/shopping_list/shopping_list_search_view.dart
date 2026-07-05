import 'dart:io';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/items_model.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../res/components/text_field_widget.dart';
import '../../view_models/providers/add_shopping_view_model.dart';
import '../../view_models/providers/shopping_list_provider.dart';
import '../add_product/slection_card_view.dart';

class ShoppingListSearchView extends ConsumerStatefulWidget {
  const ShoppingListSearchView({super.key});

  @override
  ConsumerState<ShoppingListSearchView> createState() =>
      _ShoppingListSearchViewState();
}

class _ShoppingListSearchViewState
    extends ConsumerState<ShoppingListSearchView> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addToShoppingList(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final viewNotifier = ref.read(shoppingListSearchProvider.notifier);
    final quantity = viewNotifier.getQuantity(product.id);
    final currentListName = ref.read(shoppingListProvider).currentListName;

    try {
      await ref
          .read(shoppingListProvider.notifier)
          .addProductToShoppingList(product: product, quantity: quantity);

      if (context.mounted) {
        AppFlushbar.success(
          context,
          message: '${product.name} (x$quantity) added to $currentListName',
        );
        // Reset quantity after adding
        viewNotifier.resetProduct(product.id);
      }
    } catch (e) {
      if (context.mounted) {
        AppFlushbar.error(context, message: 'Error adding item: $e');
      }
    }
  }

  Future<void> _navigateToAddCustomItem(
    BuildContext context,
    String searchQuery,
  ) async {
    // Navigate to product selection with the search query as initial name
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ProductTypeSelectionScreen(
              initialName: searchQuery.isNotEmpty ? searchQuery : null,
            ),
      ),
    );

    // Reload products when returning from add screen
    if (result == true || result == null) {
      ref.read(shoppingListSearchProvider.notifier).loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewState = ref.watch(shoppingListSearchProvider);
    final viewNotifier = ref.read(shoppingListSearchProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show error message if any
    if (viewState.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppFlushbar.error(context, message: viewState.errorMessage!);
      });
    }

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        context: context,
        title: 'Search & Add Items',
      ),
      body:
          viewState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.md.h,
                      vertical: AppSizes.md.h,
                    ),
                    child: CustomTextField(
                      controller: _searchController,
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, size: 20.spMin),
                      onChange: (value) {
                        viewNotifier.filterProducts(value ?? '');
                        return null;
                      },
                    ),
                  ),

                  // Current List Indicator
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.grey800 : AppColors.grey100,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.list_alt,
                          color: AppColors.primary,
                          size: 16.spMin,
                        ),
                        SizedBox(width: 8.w),
                        smText(text: 'Adding to: '),
                        smTextBold(
                          text: ref.watch(shoppingListProvider).currentListName,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Products List
                  Expanded(
                    child:
                        viewState.filteredProducts.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64.spMin,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16.h),
                                  smText(text: 'No products found'),
                                  SizedBox(height: 16.h),
                                  if (_searchController.text.isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed:
                                          () => _navigateToAddCustomItem(
                                            context,
                                            _searchController.text,
                                          ),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add Custom Item'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                      ),
                                    ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSizes.md.h,
                                vertical: AppSizes.md.h,
                              ),
                              itemCount: viewState.filteredProducts.length + 1,
                              itemBuilder: (context, index) {
                                // Add Custom Item button at the end
                                if (index ==
                                    viewState.filteredProducts.length) {
                                  if (_searchController.text.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          () => _navigateToAddCustomItem(
                                            context,
                                            _searchController.text,
                                          ),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                      ),
                                      label: Text(
                                        'Add "${_searchController.text}" as Custom Item',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: EdgeInsets.all(16.w),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                final product =
                                    viewState.filteredProducts[index];
                                final isExpanded = viewState.expandedItems
                                    .contains(product.id);
                                final quantity = viewNotifier.getQuantity(
                                  product.id,
                                );

                                return _buildProductCard(
                                  context,
                                  ref,
                                  product,
                                  isExpanded,
                                  quantity,
                                  isDark,
                                  viewNotifier,
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    WidgetRef ref,
    Product product,
    bool isExpanded,
    int quantity,
    bool isDark,
    ShoppingListSearchNotifier notifier,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
        side: BorderSide(
          color:
              isExpanded
                  ? AppColors.primary
                  : (isDark ? AppColors.grey700 : AppColors.grey300),
          width: isExpanded ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Main Product Info
          InkWell(
            onTap: () => notifier.toggleExpanded(product.id),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.sm.h,
                vertical: AppSizes.sm.h,
              ),
              child: Row(
                children: [
                  // Product Image
                  Stack(
                    children: [
                      Container(
                        width: 65.spMin,
                        height: 65.spMin,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.grey700 : AppColors.grey200,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child:
                            product.imageUrl != null &&
                                    product.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.file(
                                    File(product.imageUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, trace) => Icon(
                                          Icons.shopping_bag,
                                          size: 30.spMin,
                                          color: Colors.grey,
                                        ),
                                  ),
                                )
                                : Icon(
                                  Icons.shopping_bag,
                                  size: 30.spMin,
                                  color: Colors.grey,
                                ),
                      ),
                      // Brand Badge
                      if (notifier.getBrandForProduct(product.id) != null &&
                          notifier.getBrandForProduct(product.id)!.imageUrl !=
                              null &&
                          notifier
                              .getBrandForProduct(product.id)!
                              .imageUrl!
                              .isNotEmpty)
                        Positioned(
                          top: 4.spMin,
                          right: 4.spMin,
                          child: SizedBox(
                            width: 15.spMin,
                            height: 15.spMin,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.r),
                              child: Image.file(
                                File(
                                  notifier
                                      .getBrandForProduct(product.id)!
                                      .imageUrl!,
                                ),
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, trace) => Icon(
                                      Icons.branding_watermark,
                                      size: 12.spMin,
                                      color: AppColors.primary,
                                    ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 12.h),
                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        smTextBold(text: product.name, maxLines: 2),
                        SizedBox(height: 4.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            customText(
                              size: 11.spMin,
                              text: 'Rs.${product.price.toStringAsFixed(0)}',
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                            if (product.stock != null) ...[
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        product.stock! > 10
                                            ? Colors.green.withValues(
                                              alpha: 0.2,
                                            )
                                            : Colors.orange.withValues(
                                              alpha: 0.2,
                                            ),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: customText(
                                    size: 10.spMin,
                                    text: 'Stock: ${product.stock}',
                                    color:
                                        product.stock! > 10
                                            ? Colors.green
                                            : Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        // if (product.brand != null) ...[
                        //   SizedBox(height: 2.h),
                        //   customText(
                        //     size: 10.spMin,
                        //     text: product.brand!,
                        //     color: Colors.grey,
                        //   ),
                        // ],
                      ],
                    ),
                  ),

                  // Expand Icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Section with Quantity Controls
          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isDark ? AppColors.dCardColor : AppColors.lCardColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.borderRadiusMd.r),
                  bottomRight: Radius.circular(AppSizes.borderRadiusMd.r),
                ),
              ),
              padding: EdgeInsets.all(12.h),
              child: Column(
                children: [
                  Divider(height: 1, color: AppColors.grey300),
                  SizedBox(height: 12.h),

                  // Quantity Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      smText(text: 'Quantity: '),
                      SizedBox(width: 12.w),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.grey300),
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadiusMd.r,
                          ),
                        ),
                        child: Row(
                          children: [
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.all(8.h),
                                child: Icon(
                                  Icons.remove,
                                  color: AppColors.primary,
                                  size: 18.spMin,
                                ),
                              ),
                              onTap:
                                  () => notifier.decrementQuantity(product.id),
                            ),
                            SizedBox(
                              height: 20.h,
                              child: VerticalDivider(color: AppColors.grey500),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: mdTextBold(
                                text: quantity.toString(),
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(
                              height: 20.h,
                              child: VerticalDivider(color: AppColors.grey500),
                            ),
                            InkWell(
                              child: Padding(
                                padding: EdgeInsets.all(8.h),
                                child: Icon(
                                  Icons.add,
                                  color: AppColors.primary,
                                  size: 18.spMin,
                                ),
                              ),
                              onTap:
                                  () => notifier.incrementQuantity(product.id),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Add to List Button
                  AppButton().primaryButton(
                    height: 30.spMin,
                    text:
                        'Add to ${ref.watch(shoppingListProvider).currentListName}',
                    onPressed: () => _addToShoppingList(context, ref, product),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
