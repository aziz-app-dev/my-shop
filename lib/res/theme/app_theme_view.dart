// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../view_models/providers/theme_view_model.dart';
import '../components/app_button.dart';

class ThemeSettings extends ConsumerStatefulWidget {
  const ThemeSettings({super.key});

  @override
  _ThemeSettingsState createState() => _ThemeSettingsState();
}

class _ThemeSettingsState extends ConsumerState<ThemeSettings>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Define Fade Animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Define Scale Animation
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start the animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.watch(themeProvider.notifier);
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20.h),

              //! Fade Animation for Theme Toggle Button
              FadeTransition(
                opacity: _fadeAnimation,
                child: AppButton().primaryButton(
                  // ref: ref,
                  onPressed: () => themeNotifier.toggleTheme(),
                  text:
                      themeState.isDarkMode
                          ? 'Switch to Light Mode'
                          : 'Switch to Dark Mode',
                ),
              ),
              SizedBox(height: 30.h),

              //! Scale Animation for Primary Color Picker
              ScaleTransition(
                scale: _scaleAnimation,
                child: AppButton().primaryButton(
                  // ref: ref,
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: themeState.primaryColor,
                                onColorChanged:
                                    (color) =>
                                        themeNotifier.updatePrimaryColor(color),
                              ),
                            ),
                          ),
                    );
                  },
                  text: 'Pick Primary Color',
                ),
              ),
              SizedBox(height: 20.h),

              //! Scale Animation for Secondary Color Picker
              ScaleTransition(
                scale: _scaleAnimation,
                child: AppButton().primaryButton(
                  // ref: ref,
                  text: 'Secondary Color',
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: themeState.secondaryColor,
                                onColorChanged:
                                    (color) => themeNotifier
                                        .updateSecondaryColor(color),
                              ),
                            ),
                          ),
                    );
                  },
                ),
              ),
              SizedBox(height: 20.h),

              //! Scale Animation for Background Color Picker
              ScaleTransition(
                scale: _scaleAnimation,
                child: AppButton().primaryButton(
                  // ref: ref,
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Pick a color'),
                            content: SingleChildScrollView(
                              child: BlockPicker(
                                pickerColor: themeState.backgroundColor,
                                onColorChanged:
                                    (color) => themeNotifier
                                        .updateBackgroundColor(color),
                              ),
                            ),
                          ),
                    );
                  },
                  text: 'Pick Background Color',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
