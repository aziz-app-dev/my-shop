// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../res/components/app_flushbar.dart';
import '../../routes/routes_name.dart';
import '../providers/settings_provider.dart';

class SplashServices {
  /// Navigate directly to the main screen after the splash animation.
  ///
  /// Auth has been removed — the app no longer checks for login state, shop
  /// setup completion, or cloud profile restore. The only first-run step
  /// retained is the directory picker (desktop) / default-path assignment
  /// (mobile) because Hive needs a storage location.
  void navigateToMain(WidgetRef ref, BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check for first-time setup (directory picker only)
      final isFirstInstall = await _checkFirstInstall();

      if (isFirstInstall) {
        final directorySet = await _showDirectoryPickerDialog(context, ref);
        if (!directorySet) {
          if (context.mounted) {
            AppFlushbar.warning(
              context,
              message: 'Please select a directory to continue',
            );
          }
          // Retry after a delay
          Timer(const Duration(seconds: 1), () {
            if (context.mounted) {
              navigateToMain(ref, context);
            }
          });
          return;
        }
      }

      // Navigate directly to MainScreen after a brief delay
      Timer(const Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, RouteName.mainScreen);
        }
      });
    });
  }

  /// Check if this is the first time the app is installed
  /// by checking if first setup was completed
  Future<bool> _checkFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final setupCompleted = prefs.getBool('firstSetupCompleted') ?? false;
    return !setupCompleted;
  }

  /// Show directory picker dialog for first-time setup
  Future<bool> _showDirectoryPickerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    String? selectedPath;

    // On mobile (Android/iOS), skip the picker entirely and use a sensible
    // default directory automatically. Only desktop asks the user to choose.
    final isMobile = Platform.isAndroid || Platform.isIOS;
    if (isMobile) {
      final appDir =
          Platform.isAndroid ? await getExternalStorageDirectory() : null;
      selectedPath =
          appDir?.path ?? (await getApplicationDocumentsDirectory()).path;

      // Save the default directory path and mark setup complete — no dialog.
      await ref.read(settingsProvider.notifier).setDirectoryPath(selectedPath);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firstSetupCompleted', true);
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: mdTextBold(text: 'Welcome! First Time Setup'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      smText(
                        text:
                            'Please select a directory where your app data will be stored.',
                        maxLines: 3,
                      ),
                      SizedBox(height: 16.h),
                      Container(
                        padding: EdgeInsets.all(12.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                selectedPath ?? 'No directory selected',
                                style: TextStyle(
                                  fontSize: 12.spMin,
                                  color:
                                      selectedPath != null
                                          ? Colors.black
                                          : Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final path =
                                    await FilePicker.platform
                                        .getDirectoryPath();
                                if (path != null) {
                                  setState(() {
                                    selectedPath = path;
                                  });
                                }
                              },
                              icon: Icon(Icons.folder_open, size: 18.spMin),
                              label: Text(
                                'Browse',
                                style: TextStyle(fontSize: 12.spMin),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      smText(
                        text:
                            'This directory will store all your products, bills, customers, and profile data.',
                        maxLines: 3,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.spMin),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedPath != null
                              ? () => Navigator.pop(ctx, true)
                              : null,
                      child: Text(
                        'Continue',
                        style: TextStyle(fontSize: 14.spMin),
                      ),
                    ),
                  ],
                ),
          ),
    );

    if (result == true && selectedPath != null) {
      // Save the directory path
      await ref.read(settingsProvider.notifier).setDirectoryPath(selectedPath!);

      // Mark first setup as completed
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('firstSetupCompleted', true);

      return true;
    }

    return false;
  }
}
