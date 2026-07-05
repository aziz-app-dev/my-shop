// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ThemeState {
  final bool isDarkMode;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;

  ThemeState({
    required this.isDarkMode,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
  });

  factory ThemeState.initial(GetStorage box) {
    return ThemeState(
      isDarkMode: box.read('isDarkMode') ?? false,
      primaryColor: Color(box.read('primaryColor') ?? 0xffff660e),
      secondaryColor: Color(
        box.read('secondaryColor') ??
            (box.read('isDarkMode') ?? false
                ? Colors.grey[800]!.value
                : Colors.grey[200]!.value),
      ),
      backgroundColor: Color(
        box.read('backgroundColor') ??
            (box.read('isDarkMode') ?? false
                ? Colors.black.value
                : Colors.white.value),
      ),
    );
  }

  ThemeState copyWith({
    bool? isDarkMode,
    Color? primaryColor,
    Color? secondaryColor,
    Color? backgroundColor,
  }) {
    return ThemeState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
