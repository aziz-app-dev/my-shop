import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeToggleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color bgColor;
  final IconData icon;
  final String title;

  const ThemeToggleButton({
    super.key,
    required this.onTap,
    required this.bgColor,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, // Fix here, call onTap directly
      child: Container(
        width: 150.w,
        height: 50.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: bgColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            spacing: 10.w,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 25.spMin,
              ),
              // SizedBox(width: 10.w),
              Text(
                title,
                style:
                    TextStyle(fontSize: 16.spMin, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
