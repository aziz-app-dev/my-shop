import 'dart:io';

import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:desktopapp/view_models/providers/sales_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/items_model.dart';

class CartItemCardWidget extends StatelessWidget {
  final MapEntry<Product, int> entry;
  final WidgetRef ref;
  const CartItemCardWidget({super.key, required this.entry, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Container(
        // Size to content with a minimum so a 2-line product name doesn't
        // overflow a rigid fixed height.
        constraints: BoxConstraints(minHeight: 60.spMin),
        padding: EdgeInsets.all(4.h),
        decoration: BoxDecoration(
          color:
              (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.dCardColor
                  : AppColors.primaryLight1),
          borderRadius: BorderRadius.all(
            Radius.circular(AppSizes.borderRadiusSm),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                spacing: 2.w,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  entry.key.imageUrl != null && entry.key.imageUrl!.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.all(
                          Radius.circular(AppSizes.borderRadiusSm),
                        ),
                        child: Image.file(
                          File(entry.key.imageUrl!),
                          fit: BoxFit.cover,
                          width: 50.spMin,
                          height: 50.spMin,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.broken_image,
                                size: 40.spMin,
                                color: Colors.grey,
                              ),
                        ),
                      )
                      : SizedBox(
                        width: 15.w,
                        child: Icon(Icons.shopping_bag, size: 25.spMin),
                      ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.spMin,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 2.spMin),
                        xsText(text: entry.key.price.toStringAsFixed(0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 4.w),
            Padding(
              padding: EdgeInsets.only(right: 1.w),
              child: Row(
                spacing: 2.h,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ActionIcon(
                    onTap:
                        () => ref
                            .read(salesProvider.notifier)
                            .removeFromCart(entry.key),
                    icon: Icons.remove,
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final currentValue =
                          ref.watch(salesProvider).cartItems[entry.key] ?? 0;
                      return smText(text: '$currentValue');
                    },
                  ),
                  ActionIcon(
                    onTap:
                        () => ref
                            .read(salesProvider.notifier)
                            .addToCart(entry.key),
                    icon: Icons.add,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionIcon extends StatelessWidget {
  const ActionIcon({super.key, required this.onTap, required this.icon});
  final VoidCallback onTap;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            (Theme.of(context).brightness == Brightness.dark
                ? AppColors.grey800
                : AppColors.primaryLight4),
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: InkWell(onTap: onTap, child: Icon(icon, size: 14.spMin)),
    );
  }
}
