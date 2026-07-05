import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

class DesktopTabLoginScreen extends StatelessWidget {
  const DesktopTabLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left half: Show an image
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://t3.ftcdn.net/jpg/02/41/43/18/360_F_241431868_8DFQpCcmpEPVG0UvopdztOAd4a6Rqsoo.jpg',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Right half: Form
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.verticalPaddingSm.h,
                    horizontal: AppSizes.horizontalPaddingSm.w,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const LoginHeader(),
                        const LoginForm(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
