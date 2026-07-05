import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../colors/app_color.dart';

enum FlushbarType { success, error, warning, info }

class AppFlushbar {
  static Future<void> show(
    BuildContext context, {
    required String message,
    FlushbarType type = FlushbarType.info,
    String? title,
    Duration duration = const Duration(seconds: 3),
    FlushbarPosition position = FlushbarPosition.TOP,
    VoidCallback? onTap,
    String? actionText,
    VoidCallback? onActionPressed,
  }) async {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case FlushbarType.success:
        backgroundColor = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case FlushbarType.error:
        backgroundColor = AppColors.error;
        icon = Icons.error_outline;
        break;
      case FlushbarType.warning:
        backgroundColor = AppColors.warning;
        icon = Icons.warning_amber_outlined;
        break;
      case FlushbarType.info:
        backgroundColor = AppColors.info;
        icon = Icons.info_outline;
        break;
    }

    Flushbar(
      title: title,
      message: message,
      duration: duration,
      flushbarPosition: position,
      backgroundColor: backgroundColor,
      icon: Icon(
        icon,
        color: Colors.white,
        size: 24.spMin,
      ),
      margin: EdgeInsets.all(12.r),
      borderRadius: BorderRadius.circular(8.r),
      titleColor: Colors.white,
      messageColor: Colors.white,
      titleSize: 14.spMin,
      messageSize: 13.spMin,
      mainButton: actionText != null && onActionPressed != null
          ? TextButton(
              onPressed: () {
                onActionPressed();
                Navigator.of(context).pop();
              },
              child: Text(
                actionText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.spMin,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap != null ? (_) => onTap() : null,
    ).show(context);
  }

  /// Shows a flushbar and navigates after it's dismissed
  static Future<void> showAndNavigate(
    BuildContext context, {
    required String message,
    required VoidCallback onDismissed,
    FlushbarType type = FlushbarType.info,
    String? title,
    Duration duration = const Duration(seconds: 2),
    FlushbarPosition position = FlushbarPosition.TOP,
  }) async {
    Color backgroundColor;
    IconData icon;

    switch (type) {
      case FlushbarType.success:
        backgroundColor = AppColors.success;
        icon = Icons.check_circle_outline;
        break;
      case FlushbarType.error:
        backgroundColor = AppColors.error;
        icon = Icons.error_outline;
        break;
      case FlushbarType.warning:
        backgroundColor = AppColors.warning;
        icon = Icons.warning_amber_outlined;
        break;
      case FlushbarType.info:
        backgroundColor = AppColors.info;
        icon = Icons.info_outline;
        break;
    }

    await Flushbar(
      title: title,
      message: message,
      duration: duration,
      flushbarPosition: position,
      backgroundColor: backgroundColor,
      icon: Icon(
        icon,
        color: Colors.white,
        size: 24.spMin,
      ),
      margin: EdgeInsets.all(12.r),
      borderRadius: BorderRadius.circular(8.r),
      titleColor: Colors.white,
      messageColor: Colors.white,
      titleSize: 14.spMin,
      messageSize: 13.spMin,
    ).show(context);

    onDismissed();
  }

  static void success(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: FlushbarType.success,
      duration: duration,
      actionText: actionText,
      onActionPressed: onActionPressed,
    );
  }

  static void error(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: FlushbarType.error,
      duration: duration,
      actionText: actionText,
      onActionPressed: onActionPressed,
    );
  }

  static void warning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: FlushbarType.warning,
      duration: duration,
      actionText: actionText,
      onActionPressed: onActionPressed,
    );
  }

  static void info(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionText,
    VoidCallback? onActionPressed,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: FlushbarType.info,
      duration: duration,
      actionText: actionText,
      onActionPressed: onActionPressed,
    );
  }
}
