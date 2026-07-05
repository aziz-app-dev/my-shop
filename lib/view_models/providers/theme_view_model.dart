// ignore_for_file: deprecated_member_use
import 'package:riverpod/legacy.dart';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../states/theme_states.dart';

class ThemeNotifier extends StateNotifier<ThemeState> {
  final GetStorage _box;

  ThemeNotifier(this._box) : super(ThemeState.initial(_box));

  void toggleTheme() {
    final isDark = !state.isDarkMode;
    state = state.copyWith(
      isDarkMode: isDark,
      backgroundColor: isDark ? Colors.black : Colors.white,
      secondaryColor: isDark ? Colors.grey[800]! : Colors.grey[200]!,
    );
    _saveToStorage();
  }

  void updatePrimaryColor(Color color) {
    state = state.copyWith(primaryColor: color);
    _saveToStorage();
  }

  void updateSecondaryColor(Color color) {
    state = state.copyWith(secondaryColor: color);
    _saveToStorage();
  }

  void updateBackgroundColor(Color color) {
    state = state.copyWith(backgroundColor: color);
    _saveToStorage();
  }

  void _saveToStorage() {
    _box.write('isDarkMode', state.isDarkMode);
    _box.write('primaryColor', state.primaryColor.value);
    _box.write('secondaryColor', state.secondaryColor.value);
    _box.write('backgroundColor', state.backgroundColor.value);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  final box = GetStorage();
  return ThemeNotifier(box);
});
