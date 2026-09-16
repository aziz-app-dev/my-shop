import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
}

final settingsPageProvider =
    StateNotifierProvider.autoDispose<SettingsPageNotifier, SettingsPageState>(
      (ref) => SettingsPageNotifier(),
    );
