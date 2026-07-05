import 'package:flutter/material.dart';

import '../../utils/app_sizes.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;

  const ResponsiveWrapper({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (AppSizes.isDesktop(context)) {
          return desktop;
        } else if (AppSizes.isTablet(context)) {
          return tablet;
        } else {
          return mobile;
        }
      },
    );
  }
}
