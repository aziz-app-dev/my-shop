// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_flushbar.dart';
import '../../routes/routes_name.dart';
import '../providers/settings_provider.dart';
import 'backup/backup_service.dart';
import 'database/database_services.dart';

class SplashServices {
  Future<bool> _authenticate(BuildContext context) async {
    final localAuth = LocalAuthentication();
    // Check for biometrics and device support (Windows Hello, etc.)
    final bool canAuthenticateWithBiometrics =
        await localAuth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await localAuth.isDeviceSupported();
    bool authenticated = false;

    if (canAuthenticate) {
      try {
        authenticated = await localAuth.authenticate(
          localizedReason: 'Authenticate to access the app',
        );
      } catch (e) {
        debugPrint('Authentication error: $e');
      }
    }

    // If device doesn't support authentication or auth failed, show PIN dialog
    if (!canAuthenticate || (!authenticated && canAuthenticate)) {
      // Fallback to PIN
      final TextEditingController pinController = TextEditingController();
      bool isPinCorrect = true;

      authenticated =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder:
                (ctx) => StatefulBuilder(
                  builder:
                      (context, setState) => AlertDialog(
                        title: mdText(text: 'Enter App Lock PIN'),
                        content: TextField(
                          controller: pinController,
                          decoration: InputDecoration(
                            labelText: 'Enter PIN (4 digits)',
                            errorText: !isPinCorrect ? 'Incorrect PIN' : null,
                          ),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          obscureText: true,
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              if (pinController.text == '1234') {
                                Navigator.pop(ctx, true);
                              } else {
                                setState(() {
                                  isPinCorrect = false;
                                });
                              }
                            },
                            child: Text(
                              'Unlock',
                              style: TextStyle(fontSize: 14.spMin),
                            ),
                          ),
                        ],
                      ),
                ),
          ) ??
          false;
    }

    return authenticated;
  }

  void isLogin(WidgetRef ref, BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settingsState = ref.read(settingsProvider);

      if (settingsState.isAppLockEnabled) {
        final isAuthenticated = await _authenticate(context);

        if (!context.mounted) return;

        if (!isAuthenticated) {
          Navigator.of(context).pop(); // close the app or splash
          return;
        }
      }

      // Check for first-time setup
      final isFirstInstall = await _checkFirstInstall();

      if (isFirstInstall) {
        // Show directory path picker dialog
        final directorySet = await _showDirectoryPickerDialog(context, ref);
        if (!directorySet) {
          // User cancelled, show dialog again or exit
          if (context.mounted) {
            AppFlushbar.warning(
              context,
              message: 'Please select a directory to continue',
            );
          }
          // Retry after a delay
          Timer(const Duration(seconds: 1), () {
            if (context.mounted) {
              isLogin(ref, context);
            }
          });
          return;
        }
      }

      // Check if profile data exists
      final hasProfileData = await _checkProfileDataExists();

      // Navigate after 1 sec
      Timer(const Duration(seconds: 1), () {
        if (context.mounted) {
          if (!hasProfileData) {
            // No profile data, navigate to profile edit page
            Navigator.pushReplacementNamed(context, RouteName.profileEdit);
          } else {
            // Profile exists, navigate to main screen
            Navigator.pushReplacementNamed(context, RouteName.mainScreen);
          }
        }
      });
    });
  }

  /// Check for cloud backup and offer to restore if available
  // ignore: unused_element
  Future<bool> _checkAndOfferBackupRestore(BuildContext context) async {
    try {
      final hiveService = HiveService();
      final backupService = BackupService(hiveService);

      // Ask user for email to check for backup
      final emailController = TextEditingController();
      String? email;

      final wantsToCheck = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.cloud_sync, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Expanded(child: mdTextBold(text: 'Restore from Cloud?')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  smText(
                    text:
                        'If you have previously backed up your data, enter your email to check for existing backups.',
                    maxLines: 3,
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Skip',
                    style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    email = emailController.text.trim();
                    Navigator.pop(ctx, true);
                  },
                  icon: Icon(Icons.search, size: 18.spMin),
                  label: Text(
                    'Check for Backup',
                    style: TextStyle(fontSize: 14.spMin),
                  ),
                ),
              ],
            ),
      );

      if (wantsToCheck != true || email == null || email!.isEmpty) {
        return false;
      }

      if (!context.mounted) return false;

      // Convert email to backup ID format
      final backupId = email!.replaceAll(RegExp(r'[^\w]'), '_');

      // Check if there's an existing backup with this email
      final hasBackup = await backupService.hasBackupForId(backupId);

      if (!hasBackup) {
        if (context.mounted) {
          AppFlushbar.info(
            context,
            message: 'No backup found for this email. Starting fresh!',
          );
        }
        return false;
      }

      // Get backup info
      final backupInfo = await backupService.getBackupInfoForId(backupId);

      if (!context.mounted) return false;

      // Show restore dialog
      final shouldRestore = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (ctx) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.cloud_download, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  Expanded(child: mdTextBold(text: 'Backup Found!')),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  smText(
                    text: 'We found an existing cloud backup for $email',
                    maxLines: 2,
                  ),
                  SizedBox(height: 12.h),
                  if (backupInfo != null) ...[
                    Container(
                      padding: EdgeInsets.all(12.h),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (backupInfo['updatedAt'] != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16.spMin,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: smText(
                                    text:
                                        'Last backup: ${_formatDate(backupInfo['updatedAt'])}',
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          // if (backupInfo['itemsCount'] != null) ...[
                          //   SizedBox(height: 4.h),
                          //   Row(
                          //     children: [
                          //       Icon(Icons.inventory_2, size: 16.spMin, color: Colors.grey),
                          //       SizedBox(width: 4.w),
                          //       smText(
                          //         text: '${backupInfo['itemsCount']} items',
                          //         color: Colors.grey.shade700,
                          //       ),
                          //     ],
                          //   ),
                          // ],
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                  smText(
                    text: 'Would you like to restore your data?',
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Skip',
                    style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: Icon(Icons.restore, size: 18.spMin),
                  label: Text(
                    'Restore Backup',
                    style: TextStyle(fontSize: 14.spMin),
                  ),
                ),
              ],
            ),
      );

      if (shouldRestore == true && context.mounted) {
        // Show progress dialog and restore with specific backup ID
        return await _performRestore(context, backupService, backupId);
      }

      return false;
    } catch (e) {
      debugPrint('Error checking backup: $e');
      return false;
    }
  }

  /// Perform the actual restore with progress dialog
  Future<bool> _performRestore(
    BuildContext context,
    BackupService backupService,
    String backupId,
  ) async {
    bool success = false;
    String statusMessage = 'Starting restore...';
    double progress = 0.0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              // Start restore process
              if (progress == 0.0) {
                backupService.restoreBackup(
                  customBackupId: backupId,
                  onProgress: (p, message) {
                    setState(() {
                      progress = p;
                      statusMessage = message;
                    });

                    if (p >= 1.0 || p < 0) {
                      // Restore complete or failed
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (context.mounted) {
                          success = p >= 1.0;
                          Navigator.pop(ctx);
                        }
                      });
                    }
                  },
                );
              }

              return AlertDialog(
                title: Row(
                  children: [
                    SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12.w),
                    mdTextBold(text: 'Restoring Backup'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: progress > 0 ? progress : null,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    smText(text: statusMessage),
                  ],
                ),
              );
            },
          ),
    );

    if (success && context.mounted) {
      AppFlushbar.success(context, message: 'Backup restored successfully!');
    }

    return success;
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  /// Check if this is the first time the app is installed
  /// by checking if first setup was completed
  Future<bool> _checkFirstInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final setupCompleted = prefs.getBool('firstSetupCompleted') ?? false;
    return !setupCompleted;
  }

  /// Check if profile data exists in the database
  Future<bool> _checkProfileDataExists() async {
    try {
      final hiveService = HiveService();
      final users = hiveService.getUsers();
      return users.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking profile data: $e');
      return false;
    }
  }

  /// Show directory picker dialog for first-time setup
  Future<bool> _showDirectoryPickerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    String? selectedPath;

    // On Android, use app's external storage directory to avoid permission issues
    final isAndroid = Platform.isAndroid;
    if (isAndroid) {
      final appDir = await getExternalStorageDirectory();
      selectedPath =
          appDir?.path ?? (await getApplicationDocumentsDirectory()).path;
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
                            isAndroid
                                ? 'Your app data will be stored in the app\'s private storage.'
                                : 'Please select a directory where your app data will be stored.',
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
                            if (!isAndroid) ...[
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
