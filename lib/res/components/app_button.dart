import 'package:desktopapp/res/colors/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../view_models/providers/theme_view_model.dart';
import 'app_icon.dart';

class AppButton {
  //! ---------------------- Primary Button ---------------------
  Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    // required WidgetRef ref,
    double width = double.infinity,
    double? height,
    Key? key,
    Color? color,
    Color textColor = Colors.white,
    double? fontSize,
    double borderRadius = 4.0,
    bool isLoading = false,
    FocusNode? focusNode,
    EdgeInsetsGeometry? padding,
  }) {
    // final theme = ref.watch(themeProvider);
    return SizedBox(
      width: width,
      height: height ?? 40.spMin,
      child: ElevatedButton(
        key: key,
        style: ElevatedButton.styleFrom(
          padding: padding,
          backgroundColor: color ?? AppColors.primary,
          // backgroundColor: color ?? theme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        focusNode: focusNode,
        child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize ?? 16.spMin,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // Handle overflow
                  maxLines: 1, // Limit to 1 line to prevent overflow
                ),
      ),
    );
  }

  //! ------------------ Secondary Button ----------------------
  Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    required WidgetRef ref,
    double width = double.infinity,
    double? height,
    Color? color,
    Color? textColor,
    double borderRadius = 4.0,
    double? fontSize,
    bool isLoading = false,
    FocusNode? focusNode,
  }) {
    final theme = ref.watch(themeProvider);
    return SizedBox(
      width: width,
      height: height ?? 40.spMin,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color ?? theme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        focusNode: focusNode,
        child:
            isLoading
                ? CircularProgressIndicator(color: theme.primaryColor)
                : Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize ?? 16.spMin,
                    fontWeight: FontWeight.bold,
                  ),
                ),
      ),
    );
  }

  //! ------------------ Icon Button ----------------------
  Widget iconButton({
    required String text,
    required VoidCallback onPressed,
    required WidgetRef ref,
    required IconData icon,
    required String win11Icon,
    double width = double.infinity,
    double? height,
    Color? color,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
    double borderRadius = 4.0,
    double? fontSize,
    bool isLoading = false,
    FocusNode? focusNode,
  }) {
    final theme = ref.watch(themeProvider);
    return SizedBox(
      width: width,
      height: height ?? 40.spMin,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        focusNode: focusNode,
        icon:
            isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : AppIcon(win11IconPath: win11Icon, defaultIcon: icon),
        label: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize ?? 16.spMin,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
