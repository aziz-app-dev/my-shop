import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../view_models/providers/theme_view_model.dart';

class GeneralException extends ConsumerStatefulWidget {
  final VoidCallback onPress;
  const GeneralException({super.key, required this.onPress});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _GeneralExceptionState();
}

class _GeneralExceptionState extends ConsumerState<GeneralException> {
  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 15.h),
            Icon(Icons.cloud_off, color: Colors.red, size: 50),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Center(
                child: Text('Gentral excetions', textAlign: TextAlign.center),
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
      ),
    );
  }
}
