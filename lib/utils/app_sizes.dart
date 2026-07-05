import 'package:flutter/material.dart';

class AppSizes {
  //! Padding and margin sizes
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  //! Icon sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  //! Font sizes
  static const double fontSizeSm1 = 12.0;
  static const double fontSizeSm2 = 14.0;
  static const double fontSizeMd = 16.0;
  static const double fontSizeLg1 = 18.0;
  static const double fontSizeLg2 = 20.0;

  //! Button sizes
  static const double buttonHeight = 18.0;
  static const double buttonRadius = 10.0;
  static const double buttonWidth = 130.0;
  static const double buttonElevation = 4.0;

  // ! AppBar Size
  static const double appBarHeight = 56.0;

  // ! imageThumbs Size
  static const double imageThumbSizes = 56.0;

  //! Default spacing between sections
  static const double defaultSpace = 24.0;
  static const double spaceMinBtwItems = 5.0;
  static const double spaceMidBtwItems = 10.0;
  static const double spaceBtwItems = 16.0;
  static const double spaceBtwSections = 32.0;

  //! Border radius
  static const double borderRadiusSm = 4.0;
  static const double borderRadiusMd = 8.0;
  static const double borderRadiusLg = 10.0;

  static const double borderRadiusWidthLg = 2.0;
  static const double borderRadiusWidthSm = 1.0;
  static const double borderRadiusWidthMd = 1.5;

  //! Divider height
  static const double dividerHeight = 1.0;

  //! Product item dimensions
  static const double productImageSize = 120.0;
  static const double productImageRadius = 16.0;
  static const double productItemHeight = 160.0;

  //! Input field
  static const double inputFieldRadius = 12.0;
  static const double spaceBtwInputFields = 16.0;
  //! Card sizes
  static const double cardRadiusLg = 16.0;
  static const double cardRadiusMd = 12.0;
  static const double cardRadiusSm = 10.0;
  static const double cardRadiusXs = 6.0;
  static const double cardElevation = 2.0;

  //! Image carousel height
  static const double imageCarouselHeight = 200.0;

  //! Loading indicator size
  static const double loadingIndicatorSize = 36.0;

  //! Grid view spacing
  static const double gridViewSpacing = 16.0;
  // ! tf padding
  static const double tFVerPadding = 12.0;
  static const double tFHorPadding = 6.0;
  //! body Paddings
  static const double verticalPaddingSm = 10.0;
  static const double verticalPaddingLg = 16.0;

  static const double horizontalPaddingSm = 10.0;
  static const double horizontalPaddingLg = 16.0;

  //! Responsive Screen Sizes
  static const int desktopScreenSize = 1366;
  static const int tabletScreenSize = 768;
  static const int mobileScreenSize = 360;
  static const int customScreenSize = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;
}
