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
import '../../res/components/app_flushbar.dart';
import '../../routes/routes_name.dart';
import '../providers/settings_provider.dart';
import 'cloud_user/cloud_user_service.dart';
import 'database/database_services.dart';
import 'firebase/firebase_auth_service.dart';

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

      // Not signed in with Firebase? Go to the login screen.
      if (!FirebaseAuthService().isSignedIn) {
        Timer(const Duration(seconds: 1), () {
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, RouteName.loginView);
          }
        });
        return;
      }

      // Signed in. Check whether a shop profile exists locally.
      bool hasProfileData = await _checkProfileDataExists();

      // No local profile yet? Try to pull it from the cloud (re-install / new
      // device for an already-set-up shop). If found, restore and go home;
      // otherwise send the user to complete their shop info.
      if (!hasProfileData) {
        hasProfileData = await _tryRestoreProfileFromCloud();
      }

      // Navigate after 1 sec
      Timer(const Duration(seconds: 1), () {
        if (context.mounted) {
          if (!hasProfileData) {
            // Signed in but no shop info yet — finish setup.
            Navigator.pushReplacementNamed(context, RouteName.profileEdit);
          } else {
            // Profile exists (local or restored from cloud), go to home.
            Navigator.pushReplacementNamed(context, RouteName.mainScreen);
          }
        }
      });
    });
  }

  /// Fetch the shop profile from Firestore and, if present, persist it
  /// locally so the rest of the app (which reads from Hive) sees it. Returns
  /// true if a cloud profile was found and saved. Any error (offline, no table,
  /// empty table) returns false so we safely fall back to account creation.
  Future<bool> _tryRestoreProfileFromCloud() async {
    try {
      final cloudUser = await CloudUserService().getFirstUser();
      if (cloudUser == null) return false;

      final dbService = DatabaseService();
      await dbService.initialize();
      await dbService.saveUser(cloudUser);
      return true;
    } catch (e) {
      debugPrint('Cloud profile restore skipped: $e');
      return false;
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
