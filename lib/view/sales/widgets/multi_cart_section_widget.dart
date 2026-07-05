import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/view_models/states/multi_cart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'multi_cart_item_widget.dart';

Widget buildMultiCartSection(
  BoxConstraints constraints,
  WidgetRef ref,
  CartSession activeCart,
  VoidCallback completeSale,
) {
  return Padding(
    padding: EdgeInsets.all(5.h),
    child: LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          xlTextBold(
                            text: activeCart.name,
                            color: AppColors.primary,
                          ),
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
                              text: '${activeCart.itemCount} items',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      if (activeCart.cartItems.isEmpty)
                        Center(
                          child: Text(
                            'Cart is empty',
                            style: TextStyle(fontSize: 12.spMin),
                          ),
                        )
                      else
                        ...activeCart.cartItems.entries.map(
                          (entry) => MultiCartItemWidget(
                            entry: entry,
                            ref: ref,
                            cartId: activeCart.id,
                          ),
                        ),
                    ],
                  ),

                  Column(
                    children: [
                      if (activeCart.cartItems.isNotEmpty)
                        Column(
                          spacing: 5.h,
                          children: [
                            // Subtotal
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.dBodyColor
                                        : AppColors.lBodyColor,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 2.h,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    mdText(text: 'Subtotal'),
                                    mdText(
                                      text:
                                          'Rs.${activeCart.totalAmount.toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Discount (if any)
                            if (activeCart.discount > 0)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(4),
                                  ),
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.dBodyColor
                                          : AppColors.lBodyColor,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 2.h,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      mdText(text: 'Discount'),
                                      mdText(
                                        text:
                                            '-Rs.${activeCart.discount.toStringAsFixed(0)}',
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Total
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(4),
                                ),
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.dBodyColor
                                        : AppColors.lBodyColor,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 2.h,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    mdTextBold(text: 'Total'),
                                    mdTextBold(
                                      text:
                                          'Rs.${(activeCart.totalAmount - activeCart.discount).toStringAsFixed(0)}',
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            AppButton().primaryButton(
                              height: 40.spMin,
                              text: 'Complete Sale',
                              onPressed: completeSale,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
