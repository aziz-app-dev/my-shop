import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../view_models/providers/theme_view_model.dart';

class InternetExceptionsWidget extends ConsumerStatefulWidget {
  final VoidCallback onPress;
  const InternetExceptionsWidget({super.key, required this.onPress});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _InternetExceptionsWidgetState();
}

class _InternetExceptionsWidgetState
    extends ConsumerState<InternetExceptionsWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(height: 15.h),
          Icon(Icons.cloud_off, color: Colors.red, size: 50),
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Center(
              child: Text(
                'Check your internet connection',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 15.h),
          InkWell(
            onTap: widget.onPress,
            child: Container(
              height: 44,
              width: 160,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Center(
                child: Text(
                  'Retry',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
