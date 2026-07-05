import 'package:flutter/material.dart';

import '../utils/app_sizes.dart';

class ResponsiveDesign extends StatelessWidget {
  final Widget desktop;
  final Widget tablet;
  final Widget mobile;

  const ResponsiveDesign({
    super.key,
    required this.desktop,
    required this.tablet,
    required this.mobile,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppSizes.desktopScreenSize) {
          return desktop;
        } else if (constraints.maxWidth >= AppSizes.tabletScreenSize) {
          return tablet;
        } else {
          return mobile;
        }
      },
    );
  }
}
