import 'package:desktopapp/res/assets/image_assets.dart';
import 'package:desktopapp/res/components/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../colors/app_color.dart';
import 'app_text_widgrt.dart';

//! ------------------- Empty Widget -------------------
class EmptyWidget1 extends StatefulWidget {
  final String? message;
  final Widget? icon;
  const EmptyWidget1({super.key, this.message, this.icon});

  @override
  State<EmptyWidget1> createState() => _EmptyWidget1State();
}

class _EmptyWidget1State extends State<EmptyWidget1> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        spacing: 5.h,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.icon ??
              AppIcon(
                defaultIcon: Icons.search_off,
                win11IconPath: ImageAssets.win11SearchClear,
                size: 60.spMin,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.grey,
              ),
          mdText(
            text: widget.message ?? "Not found",
            color:
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
