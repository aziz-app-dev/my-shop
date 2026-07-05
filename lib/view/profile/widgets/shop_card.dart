import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../res/assets/image_assets.dart';
import '../../../view_models/providers/product_view.dart';
import '../../../view_models/providers/profile_provider.dart';
import 'owner_card.dart';

class ShopCard extends ConsumerWidget {
  const ShopCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final productsAsync = ref.watch(productsProvider); // Watch the products

    return Card(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 15.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop logo and info section (unchanged)
            Row(
              spacing: 4.w,
              children: [
                GestureDetector(
                  onTap:
                      profileState.isEditing
                          ? () async {
                            await ref
                                .read(profileProvider.notifier)
                                .pickUserImage();
                          }
                          : null,
                  child: Container(
                    height: 45.spMin,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child:
                        profileState.shopLogo != null
                            ? Image.file(
                              profileState.shopLogo!,
                              fit: BoxFit.cover,
                            )
                            : Icon(
                              Icons.person,
                              size: 40.spMin,
                              color: Colors.grey,
                            ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mdTextBold(text: profileState.shopName ?? ''),
                    Text(
                      profileState.shopTagline ?? "",
                      style: GoogleFonts.kaushanScript(
                        textStyle: TextStyle(
                          fontSize: 12.spMin,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Products data display
            productsAsync.when(
              data: (products) {
                final productCount =
                    products.where((product) => !product.isService).length;
                final totalStock = products
                    .where(
                      (product) => !product.isService && product.stock != null,
                    )
                    .fold<int>(0, (sum, product) => sum + (product.stock ?? 0));
                final serviceCount =
                    products.where((product) => product.isService).length;

                return Column(
                  children: [
                    textRow(
                      'Total Products',
                      '$productCount',
                      TablerIcons.package,
                      ImageAssets.win11Stock,
                    ),
                    SizedBox(height: 10.h),
                    textRow(
                      'Total Stock',
                      '$totalStock',
                      TablerIcons.stack_3,
                      ImageAssets.win11AppsTab,
                    ),
                    SizedBox(height: 10.h),
                    textRow(
                      'Total Services',
                      '$serviceCount',
                      TablerIcons.settings_bolt,
                      ImageAssets.win11Services,
                    ),
                  ],
                );
              },
              loading:
                  () => textRow(
                    'Products & Services',
                    'Loading...',
                    TablerIcons.package,
                    ImageAssets.win11RotateLeft,
                  ),
              error:
                  (error, stackTrace) => textRow(
                    'Products & Services',
                    'Error: $error',
                    TablerIcons.loader,
                    ImageAssets.win11Siren,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
