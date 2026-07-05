import 'package:flutter/material.dart';

import '../home/rapper.dart';
import 'responsive_views/desktop_tab_view.dart';
import 'responsive_views/mobile_view.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWrapper(
        desktop: const DesktopTabLoginScreen(),
        mobile: const MobileLoginScreen(),
        tablet: const MobileLoginScreen(),
      ),
    );
  }
}
