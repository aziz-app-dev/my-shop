import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import '../states/settings_page_state.dart';
import './settings_provider.dart';
import 'package:riverpod/legacy.dart';

class SettingsPageNotifier extends StateNotifier<SettingsPageState> {
  SettingsPageNotifier() : super(const SettingsPageState());

  Future<bool> pickNewDirectory(BuildContext context, WidgetRef ref) async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      final result = await FilePicker.platform.getDirectoryPath();
      final currentPath = ref.read(settingsProvider).directoryPath;

      if (result != null && result != currentPath) {
        if (!context.mounted) {
          state = state.copyWith(isProcessing: false);
          return false;
        }

        final confirm = await showDialog<bool>(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: mdTextBold(text: 'Change Directory'),
                content: smText(
                  text:
                      'Changing the directory may cause data loss. Do you want to migrate and continue?',
                  maxLines: 5,
                ),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: mdTextBold(text: 'Cancel'),
                        ),
                      ),
                      Expanded(
                        child: AppButton().primaryButton(
                          height: 35.spMin,
                          text: 'Yes, migrate',
                          onPressed: () => Navigator.pop(ctx, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        );

        if (confirm == true) {
          await ref.read(settingsProvider.notifier).setDirectoryPath(result);
          state = state.copyWith(isProcessing: false);
          return true;
        }
      }

      state = state.copyWith(isProcessing: false);
      return false;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> enableAppLock(BuildContext context, WidgetRef ref) async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

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
            localizedReason: 'Authenticate to enable app lock',
          );
        } catch (e) {
          debugPrint('Authentication error: $e');
          // Don't return false, fall through to PIN dialog
        }
      }

      // If device doesn't support authentication or auth failed, show PIN dialog
      if (!canAuthenticate || (!authenticated && canAuthenticate)) {
        // Fallback to PIN
        if (!context.mounted) {
          state = state.copyWith(isProcessing: false);
          return false;
        }

        final TextEditingController pinController = TextEditingController();
        final TextEditingController confirmPinController =
            TextEditingController();
        final ValueNotifier<bool> pinsMatchNotifier = ValueNotifier<bool>(true);

        authenticated =
            await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => ValueListenableBuilder<bool>(
                    valueListenable: pinsMatchNotifier,
                    builder:
                        (context, pinsMatch, child) => AlertDialog(
                          title: mdTextBold(text: 'Set App Lock PIN'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: pinController,
                                decoration: InputDecoration(
                                  labelText: 'Enter PIN (4 digits)',
                                  errorText:
                                      pinController.text.length != 4 &&
                                              pinController.text.isNotEmpty
                                          ? 'PIN must be 4 digits'
                                          : null,
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: true,
                              ),
                              TextField(
                                controller: confirmPinController,
                                decoration: InputDecoration(
                                  labelText: 'Confirm PIN',
                                  errorText:
                                      !pinsMatch ? 'PINs do not match' : null,
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: true,
                                onChanged: (value) {
                                  pinsMatchNotifier.value =
                                      pinController.text ==
                                      confirmPinController.text;
                                },
                              ),
                            ],
                          ),
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: mdTextBold(text: 'Cancel'),
                                  ),
                                ),
                                Expanded(
                                  child: AppButton().primaryButton(
                                    height: 35.spMin,
                                    text: 'Set PIN',
                                    onPressed: () {
                                      if (pinController.text.length == 4 &&
                                          pinController.text ==
                                              confirmPinController.text) {
                                        Navigator.pop(ctx, true);
                                      } else {
                                        pinsMatchNotifier.value = false;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                  ),
            ) ??
            false;

        pinsMatchNotifier.dispose();
      }

      if (authenticated) {
        ref.read(settingsProvider.notifier).setAppLockEnabled(true);
        state = state.copyWith(isProcessing: false);
        return true;
      }

      state = state.copyWith(isProcessing: false);
      return false;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }
}

final settingsPageProvider =
    StateNotifierProvider.autoDispose<SettingsPageNotifier, SettingsPageState>(
      (ref) => SettingsPageNotifier(),
    );
