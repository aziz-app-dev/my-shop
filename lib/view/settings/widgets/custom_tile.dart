import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';

Widget customTileWidget(
  BuildContext context,
  VoidCallback onTap,
  String title,
  String subTitle,
  Color color,
  IconData icon,
  String win11IconPath,
) {
  return InkWell(
    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
    onTap: onTap,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
      child: Row(
        spacing: 9.h,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm.r),
            ),
            child: AppIcon(
              defaultIcon: icon,
              win11IconPath: win11IconPath,
              size: 22.spMin,
            ),
            // Icon(icon, color: color, size: 22.spMin),
          ),

          // ✅ Added Expanded to prevent overflow
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                smText(text: title),
                xsText(text: subTitle, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
