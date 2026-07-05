import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/view_models/providers/sales_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'check_out_view.dart';
import 'widgets/items_card_widget.dart';

/// Mobile cart bottom sheet for single cart mode
class MobileCartBottomSheet extends ConsumerStatefulWidget {
  const MobileCartBottomSheet({super.key});

  @override
  ConsumerState<MobileCartBottomSheet> createState() =>
      _MobileCartBottomSheetState();
}

class _MobileCartBottomSheetState extends ConsumerState<MobileCartBottomSheet> {
  bool _isNavigating = false;

  Future<void> _navigateToCheckout() async {
    if (_isNavigating) return;

    final salesState = ref.read(salesProvider);

    setState(() {
      _isNavigating = true;
    });

    try {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder:
              (context) => CustomerPaymentScreen(
                totalAmount: salesState.totalAmount,
                discount: salesState.discount,
              ),
        ),
      );

      // If checkout completed, close bottom sheet and return result
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  void _clearCart() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Clear Cart'),
            content: const Text(
              'Are you sure you want to clear all items from cart?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  ref.read(salesProvider.notifier).resetCart();
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Close bottom sheet
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesState = ref.watch(salesProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9, // 90% of screen height
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.grey900
                : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: EdgeInsets.only(top: 12.h),
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    xlTextBold(text: 'Cart', color: AppColors.primary),
                    SizedBox(width: 8.w),
                    if (salesState.cartItems.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight1,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: smText(
                          text: '${salesState.cartItems.length} items',
                        ),
                      ),
                  ],
                ),
                Row(
                  children: [
                    if (salesState.cartItems.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          TablerIcons.trash,
                          size: 20.spMin,
                          color: Colors.red,
                        ),
                        tooltip: 'Clear Cart',
                        onPressed: _clearCart,
                      ),
                    IconButton(
                      icon: Icon(TablerIcons.x, size: 24.spMin),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // Body
          Expanded(
            child:
                salesState.cartItems.isEmpty
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
                            style: TextStyle(
                              fontSize: 18.spMin,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Add products to start a sale',
                            style: TextStyle(
                              fontSize: 14.spMin,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.all(12.h),
                      itemCount: salesState.cartItems.length,
                      itemBuilder: (context, index) {
                        final entry = salesState.cartItems.entries.elementAt(
                          index,
                        );
                        return CartItemCardWidget(entry: entry, ref: ref);
                      },
                    ),
          ),
          // Bottom Summary Section
          if (salesState.cartItems.isNotEmpty)
            Container(
              padding: EdgeInsets.all(16.h),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.grey800
                        : AppColors.grey100,
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
                              'Rs.${salesState.totalAmount.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    if (salesState.discount > 0) ...[
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          mdText(text: 'Discount'),
                          mdText(
                            text:
                                '-Rs.${salesState.discount.toStringAsFixed(2)}',
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
                              'Rs.${(salesState.totalAmount - salesState.discount).toStringAsFixed(2)}',
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
                        text: _isNavigating ? 'Loading...' : 'Complete Sale',
                        isLoading: _isNavigating,
                        onPressed: _navigateToCheckout,
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
