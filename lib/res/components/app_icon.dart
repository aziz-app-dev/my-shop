import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../view_models/providers/settings_provider.dart';

/// A simple widget that shows either a Material icon or Windows 11 PNG based on settings.
///
/// Usage:
/// ```dart
/// AppIcon(
///   defaultIcon: Icons.home,
///   win11IconPath: 'assets/win_11/home-48.png',
/// )
/// ```
class AppIcon extends ConsumerWidget {
  /// The default Material icon to show
  final IconData defaultIcon;

  /// The Windows 11 PNG icon path (optional)
  final String? win11IconPath;

  /// Icon size (defaults to 24)
  final double? size;
  final double? imgSize;

  /// Icon color (optional)
  final Color? color;

  const AppIcon({
    super.key,
    required this.defaultIcon,
    this.win11IconPath,
    this.size,
    this.color,
    this.imgSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconStyle = ref.watch(settingsProvider.select((s) => s.iconStyle));
    final iconSize = size ?? 24.spMin;

    // If Windows 11 style is selected and we have a win11 path, show the PNG
    if (iconStyle == IconStyle.windows11 && win11IconPath != null) {
      return Image.asset(
        win11IconPath!,
        width: imgSize ?? iconSize,
        height: imgSize ?? iconSize,
        // color: color,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to default icon if image fails to load
          return Icon(defaultIcon, size: iconSize, color: color);
        },
      );
    }

    // Default: show Material icon
    return Icon(defaultIcon, size: iconSize, color: color);
  }
}

/// For use in non-Consumer widgets where you need to pass IconStyle manually
class AppIconStatic extends StatelessWidget {
  final IconData defaultIcon;
  final String? win11IconPath;
  final IconStyle iconStyle;
  final double? size;
  final Color? color;

  const AppIconStatic({
    super.key,
    required this.defaultIcon,
    this.win11IconPath,
    required this.iconStyle,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? 24.spMin;

    if (iconStyle == IconStyle.windows11 && win11IconPath != null) {
      return Image.asset(
        win11IconPath!,
        width: iconSize,
        height: iconSize,
        color: color,
        errorBuilder: (context, error, stackTrace) {
          return Icon(defaultIcon, size: iconSize, color: color);
        },
      );
    }

    return Icon(defaultIcon, size: iconSize, color: color);
  }
}
