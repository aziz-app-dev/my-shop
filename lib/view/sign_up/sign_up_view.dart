import 'package:flutter/material.dart';

import '../home/rapper.dart';
import 'reposeive_screen/desktop_and_tab_view.dart';
import 'reposeive_screen/mobile_view.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveWrapper(
        desktop: DesktopTabSignUpScreen(),
        mobile: MobileSignUpScreen(),
        tablet: MobileSignUpScreen(),
      ),
    );
  }
}
