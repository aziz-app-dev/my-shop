// import 'package:desktopapp/res/colors/app_color.dart';
// import 'package:desktopapp/res/components/app_button.dart';
// import 'package:desktopapp/res/components/app_text_widgrt.dart';
// import 'package:desktopapp/view_models/providers/sales_provider.dart';
// import 'package:desktopapp/view_models/states/sales_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'items_card_widget.dart';

// Widget buildCartSection(
//   BoxConstraints constraints,
//   WidgetRef ref,
//   VoidCallback completeSale,
// ) {
//   final salesState = ref.watch(salesProvider);

//   return Padding(
//     padding: EdgeInsets.all(5.h),
//     child: LayoutBuilder(
//       builder: (context, constraints) {
//         return SingleChildScrollView(
//           child: ConstrainedBox(
//             constraints: BoxConstraints(minHeight: constraints.maxHeight),
//             child: IntrinsicHeight(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.start,
//                 children: [
//                   xlTextBold(text: 'Cart', color: AppColors.primary),
//                   SizedBox(height: 16.h),
//                   if (salesState.cartItems.isEmpty)
//                     Center(
//                       // child: Text(
//                       //   'Cart is empty',
//                       //   style: TextStyle(fontSize: 12.spMin),
//                       // ),
//                     )
//                   else
//                     ...salesState.cartItems.entries.map(
//                       (entry) => CartItemCardWidget(entry: entry, ref: ref),
//                     ),
//                   salesState.cartItems.isEmpty
//                       ? SizedBox.shrink()
//                       : Column(
//                         children: [
//                           Divider(thickness: 1.h, color: AppColors.divider),
//                           Padding(
//                             padding: EdgeInsets.symmetric(horizontal: 8.0),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 mdTextBold(text: 'SubTotal'),
//                                 mdTextBold(
//                                   text:
//                                       'Rs.${salesState.totalAmount.toStringAsFixed(0)}',
//                                 ),
//                               ],
//                             ),
//                           ),
//                           Divider(thickness: 1.h, color: AppColors.divider),
//                         ],
//                       ),
//                   // Push the payment status, method (if applicable), and button to the bottom
//                   Expanded(
//                     child: Align(
//                       alignment: Alignment.bottomCenter,
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Payment Status Section
//                           Text(
//                             'Payment Status',
//                             style: TextStyle(
//                               fontSize: 14.spMin,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           SizedBox(height: 8.h),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               // Paid Container
//                               PaymentContaienr(
//                                 onTap: () {
//                                   ref
//                                       .read(salesProvider.notifier)
//                                       .setPaymentStatus(true);
//                                 },
//                                 salesState: salesState,
//                                 title: 'Paid',
//                                 isPaymentStatus: true,
//                               ),
//                               SizedBox(width: 4.w),
//                               // Pending Container
//                               PaymentContaienr(
//                                 onTap: () {
//                                   ref
//                                       .read(salesProvider.notifier)
//                                       .setPaymentStatus(false);
//                                 },
//                                 salesState: salesState,
//                                 title: 'Pending',
//                                 isPaymentStatus: true,
//                               ),
//                             ],
//                           ),
//                           // Animated Payment Method Section
//                           AnimatedSwitcher(
//                             duration: const Duration(milliseconds: 300),
//                             transitionBuilder: (
//                               Widget child,
//                               Animation<double> animation,
//                             ) {
//                               return SizeTransition(
//                                 sizeFactor: animation,
//                                 axis: Axis.vertical,
//                                 child: FadeTransition(
//                                   opacity: animation,
//                                   child: child,
//                                 ),
//                               );
//                             },
//                             child:
//                                 salesState.isPaid
//                                     ? Column(
//                                       key: const ValueKey('paymentMethod'),
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         SizedBox(height: 16.h),
//                                         Text(
//                                           'Payment Method',
//                                           style: TextStyle(
//                                             fontSize: 14.spMin,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                         SizedBox(height: 8.h),
//                                         Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.start,
//                                           children: [
//                                             // Cash Container
//                                             PaymentContaienr(
//                                               onTap: () {
//                                                 ref
//                                                     .read(
//                                                       salesProvider.notifier,
//                                                     )
//                                                     .setPaymentMethod('Cash');
//                                               },
//                                               salesState: salesState,
//                                               title: 'Cash',
//                                             ),
//                                             SizedBox(width: 4.w),
//                                             // Online Pay Container
//                                             PaymentContaienr(
//                                               onTap: () {
//                                                 ref
//                                                     .read(
//                                                       salesProvider.notifier,
//                                                     )
//                                                     .setPaymentMethod(
//                                                       'Online Pay',
//                                                     );
//                                               },
//                                               salesState: salesState,
//                                               title: 'Online Pay',
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     )
//                                     : const SizedBox.shrink(
//                                       key: ValueKey('empty'),
//                                     ),
//                           ),
//                           SizedBox(height: 10.h),
//                           AppButton().primaryButton(
//                             height: 35,
//                             text: 'Complete Sale',
//                             onPressed: completeSale,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     ),
//   );
// }

// class PaymentContaienr extends StatelessWidget {
//   final Function()? onTap;
//   final String title;
//   final SalesState salesState;
//   final bool
//   isPaymentStatus; // Add this to differentiate between payment method and status

//   const PaymentContaienr({
//     super.key,
//     required this.salesState,
//     this.onTap,
//     required this.title,
//     this.isPaymentStatus = false, // Default to false (for payment method)
//   });

//   @override
//   Widget build(BuildContext context) {
//     // Determine if this container is selected based on whether it's for payment status or method
//     final bool isSelected =
//         isPaymentStatus
//             ? (title == 'Paid' && salesState.isPaid) ||
//                 (title == 'Pending' && !salesState.isPaid)
//             : salesState.paymentMethod == title;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
//         decoration: BoxDecoration(
//           color: isSelected ? AppColors.primaryLight1 : AppColors.grey200,
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(
//             color: isSelected ? AppColors.primary : AppColors.divider,
//           ),
//         ),
//         child: Text(
//           title,
//           style: TextStyle(
//             fontSize: 10.spMin,
//             fontWeight: FontWeight.bold,
//             color: isSelected ? AppColors.background : AppColors.textPrimary,
//           ),
//           overflow: TextOverflow.ellipsis, // Handle overflow
//           maxLines: 1, // Limit to 1 line to prevent overflow
//         ),
//       ),
//     );
//   }
// }

import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/view_models/providers/sales_provider.dart';
import 'package:desktopapp/view_models/states/sales_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'items_card_widget.dart';

Widget buildCartSection(
  BoxConstraints constraints,
  WidgetRef ref,
  VoidCallback completeSale,
) {
  final salesState = ref.watch(salesProvider);

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
                      xlTextBold(text: 'Cart', color: AppColors.primary),
                      SizedBox(height: 16.h),
                      if (salesState.cartItems.isEmpty)
                        Center(
                          child: Text(
                            'Cart is empty',
                            style: TextStyle(fontSize: 12.spMin),
                          ),
                        )
                      else
                        ...salesState.cartItems.entries.map(
                          (entry) => CartItemCardWidget(entry: entry, ref: ref),
                        ),
                    ],
                  ),

                  Column(
                    children: [
                      salesState.cartItems.isEmpty
                          ? SizedBox.shrink()
                          : Column(
                            spacing: 5.h,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(4),
                                  ),
                                  color:
                                      (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.dBodyColor
                                          : AppColors.lBodyColor),
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
                                            'Rs.${(salesState.totalAmount - salesState.discount).toStringAsFixed(0)}',
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
                      // Push the button to the bottom
                      // Expanded(
                      //   child: Align(
                      //     alignment: Alignment.bottomCenter,
                      //     child: AppButton().primaryButton(
                      //       height: 35,
                      //       text: 'Complete Sale',
                      //       onPressed: completeSale,
                      //     ),
                      //   ),
                      // ),
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

class PaymentContaienr extends StatelessWidget {
  final Function()? onTap;
  final String title;
  final SalesState salesState;
  final bool
  isPaymentStatus; // Add this to differentiate between payment method and status

  const PaymentContaienr({
    super.key,
    required this.salesState,
    this.onTap,
    required this.title,
    this.isPaymentStatus = false, // Default to false (for payment method)
  });

  @override
  Widget build(BuildContext context) {
    // Determine if this container is selected based on whether it's for payment status or method
    final bool isSelected =
        isPaymentStatus
            ? (title == 'Paid' && salesState.isPaid) ||
                (title == 'Pending' && !salesState.isPaid)
            : salesState.paymentMethod == title;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight1 : AppColors.grey200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10.spMin,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.background : AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis, // Handle overflow
          maxLines: 1, // Limit to 1 line to prevent overflow
        ),
      ),
    );
  }
}
