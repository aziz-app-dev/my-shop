import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        xlTextBold(text: 'Welcome Back'),
        SizedBox(height: 10.h),
        mdText(text: 'Login to access your shop'),
        SizedBox(height: 20.h),
      ],
    );
  }
}
