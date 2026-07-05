import 'package:desktopapp/res/assets/image_assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';

Widget buildSectionHeader(
  String title,
  IconData icon,
  String win11Icon,
  Color color, {
  VoidCallback? onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8.r),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.spMin),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: AppIcon(
            win11IconPath: win11Icon,
            defaultIcon: icon,
            color: color,
            size: 22.spMin,
          ),
        ),
        SizedBox(width: 12.h),
        Expanded(child: lgTextBold(text: title)),
        if (onTap != null) ...[
          SizedBox(width: 8.w),
          AppIcon(
            win11IconPath: ImageAssets.win11Forward,
            defaultIcon: Icons.arrow_forward_ios,
            size: 16.spMin,
          ),
        ],
      ],
    ),
  );
}
