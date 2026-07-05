// ignore_for_file: use_build_context_synchronously

import 'package:desktopapp/res/assets/image_assets.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/items_model.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/text_field_widget.dart';
import '../../view_models/services/database/database_services.dart';
import '../../view_models/providers/product_view.dart';
import '../../view_models/providers/home_page_provider.dart';
import '../../view_models/providers/sales_provider.dart';
import '../add_product/add_product_view.dart';
import '../home/rapper.dart';
import 'responsive_views/mobile_details_view.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _showStockDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text('Add Stock', style: TextStyle(fontSize: 18.spMin)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Stock: ${widget.product.stock ?? 0} units',
                  style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  hintText: 'Enter quantity',
                  controller: controller,
                  keyboardType: TextInputType.number,
                  prefixIcon: AppIcon(
                    win11IconPath: ImageAssets.win11Add,
                    defaultIcon: Icons.add,
                  ),
                ),
              ],
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.spMin),
                      ),
                    ),
                  ),
                  Expanded(
                    child: AppButton().primaryButton(
                      text: 'Add Stock',
                      height: 35.spMin,
                      onPressed: () async {
                        final quantity = int.tryParse(controller.text);
                        if (quantity == null || quantity <= 0) {
                          AppFlushbar.error(
                            context,
                            message: 'Please enter a valid quantity',
                          );
                          return;
                        }

                        final currentStock = widget.product.stock ?? 0;
                        final updatedProduct = Product(
                          id: widget.product.id,
                          name: widget.product.name,
                          price: widget.product.price,
                          stock: currentStock + quantity,
                          description: widget.product.description,
                          imageUrl: widget.product.imageUrl,
                          isService: widget.product.isService,
                          purchasePrice: widget.product.purchasePrice,
                          isBackup: widget.product.isBackup,
                          createdAt: widget.product.createdAt,
                          updatedAt: DateTime.now(),
                          warranty: widget.product.warranty,
                          condition: widget.product.condition,
                          brand: widget.product.brand,
                          fieldConfigs: widget.product.fieldConfigs,
                        );

                        await _dbService.updateProduct(updatedProduct);

                        // Refresh products in all providers to update UI across the app
                        ref
                            .read(productsNotifierProvider.notifier)
                            .refreshProducts();
                        ref.read(homePageProvider.notifier).refreshProducts();
                        // Also refresh the sales page products
                        ref.invalidate(productsFutureProvider);

                        if (mounted) {
                          Navigator.pop(dialogContext);
                          Navigator.pop(
                            context,
                            true,
                          ); // Return to previous screen
                          AppFlushbar.success(
                            context,
                            message: 'Stock updated: +$quantity units',
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Product Details',
        context: context,
        actions: [
          PopupMenuButton<String>(
            icon: AppIcon(
              win11IconPath: ImageAssets.win11MenuVertical,
              defaultIcon: Icons.more_vert,
              size: 22.spMin,
            ),
            onSelected: (value) async {
              if (value == 'edit') {
                final result = await Navigator.push<dynamic>(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddProductScreen(
                          product: widget.product,
                          isService: widget.product.isService,
                        ),
                  ),
                );
                // If product was updated, pop back to list with result
                if (result is Map && result['success'] == true && mounted) {
                  Navigator.of(context).pop(result);
                }
              } else if (value == 'stock') {
                _showStockDialog();
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        AppIcon(
                          win11IconPath: ImageAssets.win11EditPencil,
                          defaultIcon: Icons.edit_outlined,
                          size: 20.spMin,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Edit Product',
                          style: TextStyle(fontSize: 14.spMin),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.product.isService)
                    PopupMenuItem<String>(
                      value: 'stock',
                      child: Row(
                        children: [
                          AppIcon(
                            win11IconPath: ImageAssets.win11Add,
                            defaultIcon: Icons.add_box_outlined,
                            size: 20.spMin,
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'Add Stock',
                            style: TextStyle(fontSize: 14.spMin),
                          ),
                        ],
                      ),
                    ),
                ],
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: ResponsiveWrapper(
        mobile: MobileProductDetailsView(product: widget.product),
        tablet: MobileProductDetailsView(product: widget.product),
        desktop: MobileProductDetailsView(product: widget.product),
      ),
    );
  }
}
