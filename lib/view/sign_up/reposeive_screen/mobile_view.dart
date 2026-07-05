import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/sign_up_from.dart';
import '../widgets/sign_up_header.dart';

class MobileSignUpScreen extends StatefulWidget {
  const MobileSignUpScreen({super.key});

  @override
  State<MobileSignUpScreen> createState() => _MobileSignUpScreenState();
}

class _MobileSignUpScreenState extends State<MobileSignUpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: 15.h,
              children: [SignUpHeader(), UserInfoFormFields()],
            ),
          ),
        ),
      ),
    );
  }
}
