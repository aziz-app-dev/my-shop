import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/sign_up_from.dart';
import '../widgets/sign_up_header.dart';

class DesktopTabSignUpScreen extends StatefulWidget {
  const DesktopTabSignUpScreen({super.key});

  @override
  State<DesktopTabSignUpScreen> createState() => _DesktopTabSignUpScreenState();
}

class _DesktopTabSignUpScreenState extends State<DesktopTabSignUpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // !Left half: Show an image
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://t3.ftcdn.net/jpg/02/41/43/18/360_F_241431868_8DFQpCcmpEPVG0UvopdztOAd4a6Rqsoo.jpg',
                  ), // Replace with your image URL or AssetImage
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          //! Right half: Form
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
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [SignUpHeader(), UserInfoFormFields()],
                        ),
                      ),
                    ],
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
