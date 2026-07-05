import 'package:desktopapp/res/colors/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../assets/image_assets.dart';
import 'app_icon.dart';

class AppBarWidget {
  //! -----------------Custom AppBar----------------------
  static AppBar customAppBar({
    required String title,
    required BuildContext context,
    List<Widget>? actions,
    VoidCallback? leadingOnTap,
    Color? iconColor,
    IconData? backIcon,
    String? winBackIcon,
    Widget? backIconWidget,
    Color? backgroundColor,
    bool? automaticallyImplyLeading,
  }) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading ?? true,
      leadingWidth: 40.h,
      shadowColor: Colors.black,
      actionsPadding: EdgeInsets.only(right: 10.w),

      leading:
          automaticallyImplyLeading ?? true
              ? IconButton(
                padding: EdgeInsets.zero,
                splashRadius: 3.r,
                splashColor: AppColors.primary.withValues(alpha: 0.2),
                highlightColor: AppColors.primary.withValues(alpha: 0.1),
                onPressed: leadingOnTap ?? () => Navigator.pop(context),
                icon:
                    backIconWidget ??
                    AppIcon(
                      win11IconPath: winBackIcon ?? ImageAssets.win11Back,
                      defaultIcon: backIcon ?? Icons.arrow_back_ios_new_rounded,
                      size: 18.spMin,
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black),
                    ),
              )
              : null,
      title: Text(title),
      centerTitle: false,
      actions: actions,
    );
  }

  //! ------------------Profile App Bar----------------------
  static AppBar profileAppBar({
    required String userName,
    String? profileImage,
    bool isLoading = false,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: Row(
        children: [
          profileImage != null && profileImage.isNotEmpty
              ? CircleAvatar(backgroundImage: NetworkImage(profileImage))
              : const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
          const SizedBox(width: 10),
          Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      actions: actions,
    );
  }
}
