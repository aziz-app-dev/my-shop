import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ColorPickerButton extends StatelessWidget {
  final String title;
  final IconData icons;
  final Color currentColor;
  final Color bgColor;
  final VoidCallback onTap;

  const ColorPickerButton({
    super.key,
    required this.currentColor,
    required this.title,
    required this.icons,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150.w,
        height: 50.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10.w,
              children: [
                Icon(
                  icons,
                  color: currentColor,
                  size: 25.spMin,
                ),
                Text(
                  title,
                  style: TextStyle(
                      fontSize: 16.spMin, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
