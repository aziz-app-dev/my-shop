import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/view_models/providers/multi_cart_provider.dart';
import 'package:desktopapp/view_models/states/multi_cart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'widgets/multi_cart_item_widget.dart';

/// Mobile cart page for multi-cart mode
class MobileMultiCartPage extends ConsumerWidget {
  final CartSession activeCart;
  final Future<void> Function() onCompleteSale;

  const MobileMultiCartPage({
    super.key,
    required this.activeCart,
    required this.onCompleteSale,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for cart updates
    final multiCartState = ref.watch(multiCartProvider);
    final currentCart = multiCartState.carts.firstWhere(
      (c) => c.id == activeCart.id,
      orElse: () => activeCart,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(TablerIcons.arrow_left, size: 24.spMin),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            xlTextBold(text: currentCart.name, color: AppColors.primary),
            SizedBox(width: 8.w),
            if (currentCart.cartItems.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight1,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: smText(text: '${currentCart.itemCount} items'),
              ),
          ],
        ),
        actions: [
          if (currentCart.cartItems.isNotEmpty)
            IconButton(
              icon: Icon(TablerIcons.trash, size: 20.spMin, color: Colors.red),
              tooltip: 'Clear Cart',
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text(
                          'Are you sure you want to clear all items from this cart?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(multiCartProvider.notifier)
                                  .clearActiveCart();
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body:
          currentCart.cartItems.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      TablerIcons.shopping_cart_off,
                      size: 80.spMin,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(fontSize: 18.spMin, color: Colors.grey),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Add products to start a sale',
                      style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Cart Items List
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(12.h),
                      itemCount: currentCart.cartItems.length,
                      itemBuilder: (context, index) {
                        final entry = currentCart.cartItems.entries.elementAt(
                          index,
                        );
                        return MultiCartItemWidget(
                          entry: entry,
                          ref: ref,
                          cartId: currentCart.id,
                        );
                      },
                    ),
                  ),
                  // Bottom Summary Section
                  Container(
                    padding: EdgeInsets.all(16.h),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? AppColors.grey800
                              : AppColors.grey100,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        topRight: Radius.circular(16.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Subtotal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              mdText(text: 'Subtotal'),
                              mdText(
                                text:
                                    'Rs.${currentCart.totalAmount.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                          if (currentCart.discount > 0) ...[
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                mdText(text: 'Discount'),
                                mdText(
                                  text:
                                      '-Rs.${currentCart.discount.toStringAsFixed(2)}',
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ],
                          Divider(height: 24.h),
                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              lgTextBold(text: 'Total'),
                              lgTextBold(
                                text:
                                    'Rs.${(currentCart.totalAmount - currentCart.discount).toStringAsFixed(2)}',
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          // Complete Sale Button
                          SizedBox(
                            width: double.infinity,
                            child: AppButton().primaryButton(
                              height: 40.spMin,
                              text: 'Complete Sale',
                              onPressed: () async {
                                // Navigate to checkout, then pop cart page when done
                                await onCompleteSale();
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
