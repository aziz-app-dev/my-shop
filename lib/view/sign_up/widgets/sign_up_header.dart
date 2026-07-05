import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../view_models/providers/signup_provider.dart';

class SignUpHeader extends ConsumerWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(signUpFormProvider);

    return Column(
      spacing: 10.h,
      children: [
        // ! text
        xlTextBold(text: 'Create an Account'),
        mdText(text: 'Set up your shop and start selling today.'),
        SizedBox(height: 1.h),
      ],
    );
  }
}
