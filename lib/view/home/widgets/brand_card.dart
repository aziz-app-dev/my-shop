import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../utils/app_sizes.dart';

/// A generic card used on the home page for both brands and categories.
///
/// It renders an image (loaded from a local file path) with a colored
/// icon fallback, plus a centered title underneath.
class BrandCard extends StatelessWidget {
  final String title;
  final String? imageUrl;
  final Color accentColor;
  final IconData fallbackIcon;
  final String fallbackWin11Icon;
  final VoidCallback onTap;

  const BrandCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.accentColor,
    required this.fallbackIcon,
    required this.fallbackWin11Icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.r),
                  topRight: Radius.circular(8.r),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildImage(),
                ),
              ),
            ),
            SizedBox(height: 8.spMin),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8.spMin,
                vertical: 2.spMin,
              ),
              child: smTextBold(
                text: title,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 6.spMin),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl == null) {
      return _fallback();
    }
    return Image.file(
      File(imageUrl!),
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8.r),
          topRight: Radius.circular(8.r),
        ),
      ),
      child: AppIcon(
        win11IconPath: fallbackWin11Icon,
        defaultIcon: fallbackIcon,
        size: 30.spMin,
        color: accentColor,
      ),
    );
  }
}

/// Shared grid layout for the brand / category carousels so both sections
/// stay visually identical.
class HomeCardGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;

  const HomeCardGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Cap the card WIDTH (not the column count) so cards stay a consistent,
    // roughly-square size on every screen. On a wide desktop, a fixed
    // `crossAxisCount` stretches each card too wide (short, flat rectangles);
    // capping the max width instead lets the column count adapt to the
    // available space while every card keeps the same footprint.
    //
    // `maxCrossAxisExtent` and `mainAxisExtent` are real pixel values, so they
    // scale via `.spMin`. On mobile the design already used 3 columns; a ~120px
    // cap yields the same 3-up layout on a 360-wide screen.
    final double maxCardWidth =
        AppSizes.isMobile(context) ? 120.spMin : 150.spMin;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCardWidth,
        crossAxisSpacing: 8.spMin,
        mainAxisSpacing: 8.spMin,
        mainAxisExtent: 120.spMin,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
