import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/components/app_icon.dart';
import '../../../view_models/providers/backup_provider.dart';
import '../../../view_models/providers/sync_provider.dart';

/// Show backup progress dialog
Future<void> showBackupDialog(BuildContext context, WidgetRef ref) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const BackupProgressDialog(),
  );
}

/// Backup progress dialog widget
class BackupProgressDialog extends ConsumerStatefulWidget {
  const BackupProgressDialog({super.key});

  @override
  ConsumerState<BackupProgressDialog> createState() =>
      _BackupProgressDialogState();
}

class _BackupProgressDialogState extends ConsumerState<BackupProgressDialog> {
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    // Start backup when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBackup();
    });
  }

  Future<void> _startBackup() async {
    if (_isStarted) return;
    setState(() {
      _isStarted = true;
    });
    await ref.read(backupProvider.notifier).startBackup();
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        children: [
          Icon(
            backupState.error != null
                ? TablerIcons.cloud_off
                : backupState.progress >= 1.0
                ? TablerIcons.cloud_check
                : TablerIcons.cloud_upload,
            color:
                backupState.error != null
                    ? Colors.red
                    : backupState.progress >= 1.0
                    ? Colors.green
                    : AppColors.primary,
            size: 28.spMin,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: lgTextBold(
              text:
                  backupState.error != null
                      ? 'Backup Failed'
                      : backupState.progress >= 1.0
                      ? 'Backup Complete'
                      : 'Backing Up...',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 350.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            if (backupState.error == null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: backupState.progress,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    backupState.progress >= 1.0
                        ? Colors.green
                        : AppColors.primary,
                  ),
                  minHeight: 12.h,
                ),
              ),
              SizedBox(height: 12.h),
              // Progress percentage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  smText(text: backupState.statusMessage),
                  mdTextBold(
                    text: '${(backupState.progress * 100).toInt()}%',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
            // Error message
            if (backupState.error != null) ...[
              Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      TablerIcons.alert_circle,
                      color: Colors.red,
                      size: 20.spMin,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: smText(
                        text: backupState.error!,
                        color: Colors.red.shade700,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Success info
            if (backupState.progress >= 1.0 && backupState.error == null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      TablerIcons.check,
                      color: Colors.green,
                      size: 20.spMin,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: smText(
                        text:
                            'Your data has been backed up to the cloud successfully!',
                        color: Colors.green.shade700,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (backupState.progress >= 1.0 || backupState.error != null)
          SizedBox(
            width: double.infinity,
            child: AppButton().primaryButton(
              height: 40.spMin,
              text: 'Close',
              onPressed: () {
                ref.read(backupProvider.notifier).reset();
                Navigator.of(context).pop();
              },
            ),
          ),
      ],
    );
  }
}

/// Show restore progress dialog
Future<void> showRestoreDialog(BuildContext context, WidgetRef ref) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const RestoreProgressDialog(),
  );
}

/// Restore progress dialog widget
class RestoreProgressDialog extends ConsumerStatefulWidget {
  const RestoreProgressDialog({super.key});

  @override
  ConsumerState<RestoreProgressDialog> createState() =>
      _RestoreProgressDialogState();
}

class _RestoreProgressDialogState extends ConsumerState<RestoreProgressDialog> {
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRestore();
    });
  }

  Future<void> _startRestore() async {
    if (_isStarted) return;
    setState(() {
      _isStarted = true;
    });
    await ref.read(backupProvider.notifier).startRestore();
  }

  @override
  Widget build(BuildContext context) {
    final backupState = ref.watch(backupProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        children: [
          Icon(
            backupState.error != null
                ? TablerIcons.cloud_off
                : backupState.progress >= 1.0
                ? TablerIcons.cloud_check
                : TablerIcons.cloud_download,
            color:
                backupState.error != null
                    ? Colors.red
                    : backupState.progress >= 1.0
                    ? Colors.green
                    : AppColors.primary,
            size: 28.spMin,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: lgTextBold(
              text:
                  backupState.error != null
                      ? 'Restore Failed'
                      : backupState.progress >= 1.0
                      ? 'Restore Complete'
                      : 'Restoring...',
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 350.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (backupState.error == null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: backupState.progress,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    backupState.progress >= 1.0
                        ? Colors.green
                        : AppColors.primary,
                  ),
                  minHeight: 12.h,
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  smText(text: backupState.statusMessage),
                  mdTextBold(
                    text: '${(backupState.progress * 100).toInt()}%',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
            if (backupState.error != null) ...[
              Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      TablerIcons.alert_circle,
                      color: Colors.red,
                      size: 20.spMin,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: smText(
                        text: backupState.error!,
                        color: Colors.red.shade700,
                        maxLines: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (backupState.progress >= 1.0 && backupState.error == null) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      TablerIcons.check,
                      color: Colors.green,
                      size: 20.spMin,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: smText(
                        text:
                            'Your data has been restored from the cloud successfully!',
                        color: Colors.green.shade700,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (backupState.progress >= 1.0 || backupState.error != null)
          SizedBox(
            width: double.infinity,
            child: AppButton().primaryButton(
              height: 40.spMin,
              text: 'Close',
              onPressed: () {
                ref.read(backupProvider.notifier).reset();
                Navigator.of(context).pop();
              },
            ),
          ),
      ],
    );
  }
}

/// Backup info card widget for settings page
class BackupInfoCard extends ConsumerWidget {
  const BackupInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupState = ref.watch(backupProvider);
    final syncAsync = ref.watch(syncControllerProvider);

    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.grey800
                : AppColors.grey100,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
        border: Border.all(
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? AppColors.grey700
                  : AppColors.grey300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                win11IconPath: ImageAssets.win11CloudSync,
                defaultIcon: TablerIcons.cloud,
                color: AppColors.primary,
                size: 24.spMin,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mdTextBold(text: 'Cloud Sync'),
                    SizedBox(height: 4.h),
                    syncAsync.when(
                      data: (controller) {
                        final s = controller.statusNotifier.value;
                        return smText(
                          text:
                              '${s.isOnline ? 'Online' : 'Offline'} • '
                              '${s.isSyncing ? 'Syncing' : 'Idle'} • '
                              '${s.queuedOps} pending',
                          color: Colors.grey,
                        );
                      },
                      loading:
                          () => smText(text: 'Starting sync...', color: Colors.grey),
                      error:
                          (e, _) => smText(
                            text: 'Sync error: ${e.toString()}',
                            color: Colors.red,
                          ),
                    ),
                    if (backupState.lastBackupTime != null)
                      smText(
                        text:
                            'Last backup: ${_formatDateTime(backupState.lastBackupTime!)}',
                        color: Colors.grey,
                      )
                    else
                      smText(text: 'No backup found', color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: AppButton().primaryButton(
                  height: 30.spMin,
                  text: 'Sync Now',
                  onPressed: () async {
                    final controller = await ref.read(
                      syncControllerProvider.future,
                    );
                    await controller.flushNow();
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppButton().secondaryButton(
                  text: "Restore",
                  textColor: AppColors.iconColor,
                  height: 30.spMin,
                  onPressed:
                      backupState.isBackingUp ||
                              backupState.isRestoring ||
                              backupState.lastBackupTime == null
                          ? () {}
                          : () => showRestoreDialog(context, ref),

                  ref: ref,
                ),
              ),
            ],
          ),
          if (backupState.lastBackupItemsCount != null) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children:
                  backupState.lastBackupItemsCount!.entries.map((entry) {
                    return _buildCountChip(entry.key, entry.value);
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountChip(String label, int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.primaryLight1,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        '$count ${label.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim()}',
        style: TextStyle(fontSize: 10.spMin, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
