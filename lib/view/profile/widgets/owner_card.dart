import 'package:desktopapp/res/colors/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/components/app_icon.dart';
import '../../../view_models/providers/profile_provider.dart';

class ShopOwnerCard extends ConsumerWidget {
  const ShopOwnerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    return Card(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 15.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    width: 45.spMin,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child:
                          profileState.userImage != null
                              ? Image.file(
                                profileState.userImage!,
                                fit: BoxFit.cover,
                              )
                              :
                              // Icon(Icons.person, size: 40.spMin, color: Colors.grey),
                              Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: AppIcon(
                                  defaultIcon: Icons.person,
                                  win11IconPath: ImageAssets.win11Administrator,
                                ),
                              ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mdTextBold(text: profileState.ownerName ?? ''),
                    smTextBold(text: 'Shop Owner', color: Colors.grey),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20.h),
            textRow(
              'Phone',
              profileState.phoneNumber ?? '',
              Icons.call,
              ImageAssets.win11Phone,
            ),
            SizedBox(height: 10.h),
            textRow(
              'email',
              profileState.email ?? '',
              Icons.email,
              ImageAssets.win11Email,
            ),
            SizedBox(height: 10.h),
            textRow(
              'address',
              profileState.shopAddress ?? '',
              Icons.location_city,
              ImageAssets.win11Location,
            ),
          ],
        ),
      ),
    );
  }
}

Widget textRow(
  String title,
  String value,
  IconData icon,
  String? win11IconPath,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        spacing: 2.w,
        children: [
          AppIcon(
            // color: Colors.grey,
            size: 18.spMin,
            defaultIcon: icon,
            win11IconPath: win11IconPath,
          ),
          // Icon(icon, color: Colors.grey, size: 18.spMin),
          smText(text: title, color: Colors.grey),
        ],
      ),
      smTextBold(text: value, maxLines: 1),
    ],
  );
}
