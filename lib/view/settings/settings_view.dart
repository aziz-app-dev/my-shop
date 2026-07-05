// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:async';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:local_auth/local_auth.dart';
import 'package:thermal_printer/thermal_printer.dart';
import '../../res/assets/image_assets.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_expansion_tile.dart';
import '../../res/components/app_icon.dart';
import '../../view_models/providers/settings_provider.dart';
import 'widgets/screens_mangement.dart';
import 'widgets/backup_dialog.dart';

class SettingsPage extends ConsumerWidget {
  final VoidCallback openDrawer;
  const SettingsPage({super.key, required this.openDrawer});

  Future<void> _pickNewDirectory(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath();
    final currentPath = ref.read(settingsProvider).directoryPath;

    if (result != null && result != currentPath) {
      final confirm = await showDialog<bool>(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: mdText(text: 'Change Directory'),
              content: smText(
                maxLines: 6,
                text:
                    'Changing the directory may cause data loss. Do you want to migrate and continue?',
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: mdText(text: 'Cancel'),
                      ),
                    ),
                    Expanded(
                      child: AppButton().primaryButton(
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
        AppFlushbar.success(
          context,
          message: 'Directory path updated and data migrated',
        );
      }
    }
  }

  Future<void> _enableAppLock(BuildContext context, WidgetRef ref) async {
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
          // persistAcrossBackgrounding keeps auth dialog when app backgrounds
        );
      } catch (e) {
        debugPrint('Authentication error: $e');
        // If biometric auth fails, show PIN dialog as fallback
        authenticated = false;
      }
    }

    // If device doesn't support authentication or auth failed, show PIN setup
    if (!canAuthenticate || (!authenticated && canAuthenticate)) {
      final TextEditingController pinController = TextEditingController();
      final TextEditingController confirmPinController =
          TextEditingController();
      bool pinsMatch = true;

      authenticated =
          await showDialog<bool>(
            context: context,
            builder:
                (ctx) => StatefulBuilder(
                  builder:
                      (context, setState) => AlertDialog(
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
                                setState(() {
                                  pinsMatch =
                                      pinController.text ==
                                      confirmPinController.text;
                                });
                              },
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
                            onPressed: () {
                              if (pinController.text.length == 4 &&
                                  pinController.text ==
                                      confirmPinController.text) {
                                Navigator.pop(ctx, true);
                              } else {
                                setState(() {
                                  pinsMatch = false;
                                });
                              }
                            },
                            child: Text(
                              'Set PIN',
                              style: TextStyle(fontSize: 14.spMin),
                            ),
                          ),
                        ],
                      ),
                ),
          ) ??
          false;
    }

    if (authenticated) {
      ref.read(settingsProvider.notifier).setAppLockEnabled(true);
      AppFlushbar.success(context, message: 'App Lock enabled successfully');
    }
  }

  void _showPrinterScanDialog(BuildContext context) {
    final printerManager = PrinterManager.instance;
    final printers = <PrinterDevice>[];
    StreamSubscription<PrinterDevice>? subscription;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              // Start scanning when dialog opens
              if (printers.isEmpty && subscription == null) {
                subscription = printerManager
                    .discovery(type: PrinterType.usb)
                    .listen(
                      (device) {
                        setState(() {
                          printers.add(device);
                        });
                      },
                      onError: (error) {
                        debugPrint('Error scanning printers: $error');
                      },
                    );
              }

              return AlertDialog(
                title: Text(
                  'USB Thermal Printers',
                  style: TextStyle(fontSize: 16.spMin),
                ),
                content: SizedBox(
                  width: 300.w,
                  height: 200.h,
                  child:
                      printers.isEmpty
                          ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16.h),
                              Text(
                                'Scanning for USB printers...',
                                style: TextStyle(fontSize: 14.spMin),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Make sure your printer is connected via USB',
                                style: TextStyle(
                                  fontSize: 12.spMin,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            itemCount: printers.length,
                            itemBuilder: (context, index) {
                              final printer = printers[index];
                              return ListTile(
                                leading: AppIcon(
                                  win11IconPath: ImageAssets.win11Print,
                                  defaultIcon: Icons.print,
                                  color: AppColors.primary,
                                ),

                                title: Text(
                                  printer.name,
                                  style: TextStyle(fontSize: 14.spMin),
                                ),
                                subtitle: Text(
                                  'VID: ${printer.vendorId ?? "N/A"} | PID: ${printer.productId ?? "N/A"}',
                                  style: TextStyle(
                                    fontSize: 11.spMin,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: AppIcon(
                                  defaultIcon: Icons.check_circle,
                                  win11IconPath: ImageAssets.win11Approval,
                                  color: Colors.green,
                                  size: 20.spMin,
                                ),
                              );
                            },
                          ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      subscription?.cancel();
                      Navigator.pop(ctx);
                    },
                    child: Text('Close', style: TextStyle(fontSize: 14.spMin)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        printers.clear();
                      });
                      subscription?.cancel();
                      subscription = printerManager
                          .discovery(type: PrinterType.usb)
                          .listen(
                            (device) {
                              setState(() {
                                printers.add(device);
                              });
                            },
                            onError: (error) {
                              debugPrint('Error scanning printers: $error');
                            },
                          );
                    },
                    child: Text(
                      'Refresh',
                      style: TextStyle(fontSize: 14.spMin),
                    ),
                  ),
                ],
              );
            },
          ),
    ).then((_) {
      subscription?.cancel();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Settings',
        backgroundColor: Colors.white,
        context: context,
        backIcon: TablerIcons.menu_3,
        automaticallyImplyLeading: false,
        leadingOnTap: () {
          openDrawer();
        },
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ListView(
          padding: EdgeInsets.symmetric(
            vertical: 16.spMin,
            horizontal: 16.spMin,
          ),
          children: [
            // General Settings ExpansionTile
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.all(16.h),
                title: mdTextBold(text: 'General Settings'),
                children: [
                  // ✅ Reusable Switch Tile Widget Pattern
                  _smallSwitchTile(
                    context: context,
                    title: 'Enable App Lock',
                    value: settingsState.isAppLockEnabled,
                    onChanged: (val) async {
                      if (val) {
                        await _enableAppLock(context, ref);
                      } else {
                        ref
                            .read(settingsProvider.notifier)
                            .setAppLockEnabled(false);
                        AppFlushbar.info(context, message: 'App Lock disabled');
                      }
                    },
                  ),
                  _smallSwitchTile(
                    context: context,
                    title: 'Enable Print Bills',
                    subtitle: 'Automatically print bills after sale completion',
                    value: settingsState.isPrintEnabled,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setPrintEnabled(val);
                      if (val) {
                        AppFlushbar.success(
                          context,
                          message:
                              settingsState.printFormat == PrintFormat.pdf
                                  ? 'Print enabled. PDF bills will be generated after each sale.'
                                  : 'Print enabled. Thermal receipts will be printed after each sale.',
                        );
                      }
                    },
                  ),
                  if (settingsState.isPrintEnabled) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        bottom: 8.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Print Format',
                            style: TextStyle(
                              fontSize: 14.spMin,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          RadioListTile<PrintFormat>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Thermal Print (USB)',
                              style: TextStyle(fontSize: 14.spMin),
                            ),
                            subtitle: Text(
                              'Print thermal receipts via USB printer',
                              style: TextStyle(
                                fontSize: 12.spMin,
                                color: Colors.grey,
                              ),
                            ),
                            value: PrintFormat.thermal,
                            groupValue: settingsState.printFormat,
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setPrintFormat(val);
                                AppFlushbar.info(
                                  context,
                                  message:
                                      'Thermal print selected. Connect USB printer to use.',
                                );
                              }
                            },
                          ),
                          RadioListTile<PrintFormat>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'PDF Print',
                              style: TextStyle(fontSize: 14.spMin),
                            ),
                            subtitle: Text(
                              'Save and open PDF bills after sale',
                              style: TextStyle(
                                fontSize: 12.spMin,
                                color: Colors.grey,
                              ),
                            ),
                            value: PrintFormat.pdf,
                            groupValue: settingsState.printFormat,
                            onChanged: (val) {
                              if (val != null) {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setPrintFormat(val);
                                AppFlushbar.info(
                                  context,
                                  message:
                                      'PDF print selected. Bills will be saved and opened.',
                                );
                              }
                            },
                          ),
                          if (settingsState.printFormat ==
                              PrintFormat.thermal) ...[
                            SizedBox(height: 8.h),
                            Divider(),
                            SizedBox(height: 8.h),
                            Text(
                              'Thermal Printer Setup',
                              style: TextStyle(
                                fontSize: 13.spMin,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Connect a USB thermal printer and scan for available devices. You can select a printer from the sales screen or bill details.',
                              style: TextStyle(
                                fontSize: 11.spMin,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            OutlinedButton.icon(
                              onPressed: () => _showPrinterScanDialog(context),
                              icon: AppIcon(
                                win11IconPath: ImageAssets.win11Print,
                                defaultIcon: Icons.print_outlined,
                                size: 18.spMin,
                              ),
                              //  Icon(Icons.print_outlined, size: 18.spMin),
                              label: Text(
                                'Scan for Printers',
                                style: TextStyle(fontSize: 12.spMin),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Divider(),
                            SizedBox(height: 8.h),
                            Text(
                              'Thermal Receipt Design',
                              style: TextStyle(
                                fontSize: 13.spMin,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children:
                                  ThermalDesign.values.map((design) {
                                    final isSelected =
                                        settingsState.thermalDesign == design;
                                    return Padding(
                                      padding: EdgeInsets.only(right: 12.w),
                                      child: InkWell(
                                        onTap: () {
                                          ref
                                              .read(settingsProvider.notifier)
                                              .setThermalDesign(design);
                                          AppFlushbar.success(
                                            context,
                                            message:
                                                '${_getThermalDesignName(design)} thermal design selected',
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                        child: Container(
                                          width: 90.w,
                                          padding: EdgeInsets.all(12.r),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? AppColors.primary
                                                      : Colors.grey.shade300,
                                              width: isSelected ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                        .withOpacity(0.1)
                                                    : null,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                _getThermalDesignIcon(design),
                                                size: 24.spMin,
                                                color:
                                                    isSelected
                                                        ? AppColors.primary
                                                        : Colors.grey,
                                              ),
                                              SizedBox(height: 6.h),
                                              Text(
                                                _getThermalDesignName(design),
                                                style: TextStyle(
                                                  fontSize: 11.spMin,
                                                  fontWeight:
                                                      isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.normal,
                                                  color:
                                                      isSelected
                                                          ? AppColors.primary
                                                          : Colors
                                                              .grey
                                                              .shade700,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  _smallSwitchTile(
                    context: context,
                    title: 'By Default Bills Paid',
                    value: settingsState.isPaid,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setIsPaid(val);
                    },
                  ),
                  _smallSwitchTile(
                    context: context,
                    title: 'Enable Multi-Cart Mode',
                    subtitle: 'Manage multiple customer carts simultaneously',
                    value: settingsState.useMultiCart,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setUseMultiCart(val);
                      AppFlushbar.info(
                        context,
                        message:
                            val
                                ? 'Multi-cart mode enabled. Restart sales screen to apply.'
                                : 'Single cart mode enabled.',
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Modules Section — show/hide optional features
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.all(16.h),
                title: mdTextBold(text: 'Modules'),
                children: [
                  _smallSwitchTile(
                    context: context,
                    title: 'Shopping List',
                    subtitle:
                        'Show the shopping list shortcut on the Home screen',
                    value: settingsState.showShoppingListModule,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setShowShoppingListModule(val);
                    },
                  ),
                  _smallSwitchTile(
                    context: context,
                    title: 'Repairs',
                    subtitle:
                        'Take items (e.g. a laptop) from clients for repair. '
                        'Adds a "Repairs" tab to the sidebar.',
                    value: settingsState.showRepairsModule,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setShowRepairsModule(val);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Bill Settings Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.all(16.h),
                title: mdTextBold(text: 'Bill Settings'),
                children: [
                  // Bill Design Selection
                  Padding(
                    padding: EdgeInsets.only(
                      left: 8.w,
                      right: 8.w,
                      bottom: 8.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bill Design',
                          style: TextStyle(
                            fontSize: 14.spMin,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Choose the design for your PDF bills',
                          style: TextStyle(
                            fontSize: 12.spMin,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 12.h,
                          children:
                              BillDesign.values.map((design) {
                                final isSelected =
                                    settingsState.billDesign == design;
                                return InkWell(
                                  onTap: () {
                                    ref
                                        .read(settingsProvider.notifier)
                                        .setBillDesign(design);
                                    AppFlushbar.success(
                                      context,
                                      message:
                                          '${_getBillDesignName(design)} design selected',
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Container(
                                    width: 80.w,
                                    padding: EdgeInsets.all(12.r),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : Colors.grey.shade300,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8.r),
                                      color:
                                          isSelected
                                              ? AppColors.primary.withOpacity(
                                                0.1,
                                              )
                                              : null,
                                    ),
                                    child: Column(
                                      children: [
                                        AppIcon(
                                          defaultIcon: _getBillDesignIcon(
                                            design,
                                          ),
                                          win11IconPath:
                                              _getBillDesignWin11Icon(design),
                                          size: 28.spMin,
                                          color:
                                              isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey,
                                        ),
                                        // Icon(
                                        //   _getBillDesignIcon(design),
                                        //   size: 28.spMin,
                                        //   color:
                                        //       isSelected
                                        //           ? AppColors.primary
                                        //           : Colors.grey,
                                        // ),
                                        SizedBox(height: 6.h),
                                        Text(
                                          _getBillDesignName(design),
                                          style: TextStyle(
                                            fontSize: 11.spMin,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color:
                                                isSelected
                                                    ? AppColors.primary
                                                    : Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 24.h),
                  // Paid Stamp Settings
                  _smallSwitchTile(
                    context: context,
                    title: 'Show Paid Stamp on Bills',
                    subtitle: 'Display a paid stamp on bills marked as paid',
                    value: settingsState.showPaidStamp,
                    onChanged: (val) {
                      if (val) {
                        _showPaidStampConfigDialog(context, ref, settingsState);
                      } else {
                        ref
                            .read(settingsProvider.notifier)
                            .setShowPaidStamp(false);
                        AppFlushbar.info(
                          context,
                          message: 'Paid stamp disabled',
                        );
                      }
                    },
                  ),
                  if (settingsState.showPaidStamp) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Stamp Configuration',
                          style: TextStyle(fontSize: 12.spMin),
                        ),
                        subtitle: Text(
                          'Text: "${settingsState.paidStampText}"${settingsState.paidStampSignature.isNotEmpty ? ', Signature: "${settingsState.paidStampSignature}"' : ''}${settingsState.showDateOnStamp ? ', With Date' : ''}',
                          style: TextStyle(
                            fontSize: 10.spMin,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: IconButton(
                          icon: AppIcon(
                            win11IconPath: ImageAssets.win11EditPencil,
                            defaultIcon: TablerIcons.edit,
                            size: 18.spMin,
                          ),
                          onPressed:
                              () => _showPaidStampConfigDialog(
                                context,
                                ref,
                                settingsState,
                              ),
                        ),
                      ),
                    ),
                  ],
                  Divider(height: 24.h),
                  // Background Watermark Settings
                  _smallSwitchTile(
                    context: context,
                    title: 'Show Background Watermark',
                    subtitle: 'Display diagonal watermark on paid bills',
                    value: settingsState.showBackgroundWatermark,
                    onChanged: (val) {
                      if (val) {
                        _showWatermarkConfigDialog(context, ref, settingsState);
                      } else {
                        ref
                            .read(settingsProvider.notifier)
                            .setShowBackgroundWatermark(false);
                        AppFlushbar.info(
                          context,
                          message: 'Background watermark disabled',
                        );
                      }
                    },
                  ),
                  if (settingsState.showBackgroundWatermark) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AppIcon(
                          defaultIcon: TablerIcons.certificate,
                          win11IconPath: ImageAssets.win11Approval,
                          size: 20.spMin,
                          color: Colors.green,
                        ),

                        title: Text(
                          'Paid Stamp Watermark',
                          style: TextStyle(fontSize: 12.spMin),
                        ),
                        subtitle: Text(
                          'Opacity: ${(settingsState.watermarkOpacity * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10.spMin,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: IconButton(
                          icon: AppIcon(
                            size: 18.spMin,
                            defaultIcon: TablerIcons.edit,
                            win11IconPath: ImageAssets.win11EditPencil,
                          ),
                          //  Icon(TablerIcons.edit, size: 18.spMin),
                          onPressed:
                              () => _showWatermarkConfigDialog(
                                context,
                                ref,
                                settingsState,
                              ),
                        ),
                      ),
                    ),
                  ],
                  Divider(height: 24.h),
                  // Bank Details on Bills
                  _smallSwitchTile(
                    context: context,
                    title: 'Show Bank Details on Bills',
                    subtitle: 'Display bank account, QR code for payments',
                    value: settingsState.showBankDetailsOnBill,
                    onChanged: (val) {
                      ref
                          .read(settingsProvider.notifier)
                          .setShowBankDetailsOnBill(val);
                      AppFlushbar.info(
                        context,
                        message:
                            val
                                ? 'Bank details will be shown on bills'
                                : 'Bank details hidden from bills',
                      );
                    },
                  ),
                  if (settingsState.showBankDetailsOnBill) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: AppIcon(
                          defaultIcon: TablerIcons.building_bank,
                          win11IconPath: ImageAssets.win11Bank,
                          size: 24.spMin,
                          color: AppColors.primary,
                        ),

                        title: Text(
                          'Bank Selection',
                          style: TextStyle(fontSize: 12.spMin),
                        ),
                        subtitle: Text(
                          'Select which bank to show on bills from your profile',
                          style: TextStyle(
                            fontSize: 10.spMin,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Bank ${settingsState.selectedBankIndex + 1}',
                            style: TextStyle(
                              fontSize: 11.spMin,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: 8.w,
                        right: 8.w,
                        bottom: 8.h,
                      ),
                      child: Text(
                        'Add or manage bank accounts in your profile settings. The selected bank\'s QR code, account number, and bank name will appear on bills.',
                        style: TextStyle(
                          fontSize: 10.spMin,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Backup Section
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.all(16.h),
                // leading: Icon(TablerIcons.cloud_upload, size: 24.spMin),
                title: mdTextBold(text: 'Backup & Restore'),
                children: const [BackupInfoCard()],
              ),
            ),
            SizedBox(height: 16.h),
            // Theme Settings ExpansionTile
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.all(16.h),
                title: mdTextBold(text: 'Theme'),
                children: [
                  RadioListTile<ThemeMode>(
                    title: smText(text: 'Light'),
                    value: ThemeMode.light,
                    groupValue: settingsState.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).setThemeMode(value);
                      }
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  RadioListTile<ThemeMode>(
                    title: smText(text: 'Dark'),
                    value: ThemeMode.dark,
                    groupValue: settingsState.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).setThemeMode(value);
                      }
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  RadioListTile<ThemeMode>(
                    title: smText(text: 'system'),
                    value: ThemeMode.system,
                    groupValue: settingsState.themeMode,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).setThemeMode(value);
                      }
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  Divider(height: 24.h),
                  Align(
                    alignment: AlignmentGeometry.center,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: smTextBold(text: 'Icon Style'),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  RadioListTile<IconStyle>(
                    title: smText(text: 'Default'),
                    value: IconStyle.defaultStyle,
                    groupValue: settingsState.iconStyle,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).setIconStyle(value);
                      }
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  RadioListTile<IconStyle>(
                    title: smText(text: 'Windows 11'),
                    value: IconStyle.windows11,
                    groupValue: settingsState.iconStyle,
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).setIconStyle(value);
                      }
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  Divider(height: 24.h),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: smTextBold(text: 'App Color'),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      children:
                          AppColorOption.colors.map((colorOption) {
                            final isSelected =
                                settingsState.primaryColorValue ==
                                colorOption.color.value;
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(settingsProvider.notifier)
                                    .setPrimaryColor(colorOption.color.value);
                                AppFlushbar.success(
                                  context,
                                  message: '${colorOption.name} color applied',
                                );
                              },
                              child: Container(
                                width: 40.w,
                                height: 40.w,
                                decoration: BoxDecoration(
                                  color: colorOption.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Colors.black
                                            : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow:
                                      isSelected
                                          ? [
                                            BoxShadow(
                                              color: colorOption.color
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ]
                                          : null,
                                ),
                                child:
                                    isSelected
                                        ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20.spMin,
                                        )
                                        : null,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Color shades preview
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: smText(text: 'Color Shades Preview'),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      children: [
                        // Dark shades
                        _colorShadeBox(settingsState.primaryDark2, 'Dark 2'),
                        SizedBox(width: 4.w),
                        _colorShadeBox(settingsState.primaryDark1, 'Dark 1'),
                        SizedBox(width: 4.w),
                        // Primary
                        _colorShadeBox(
                          settingsState.primaryColor,
                          'Primary',
                          isMain: true,
                        ),
                        SizedBox(width: 4.w),
                        // Light shades
                        _colorShadeBox(settingsState.primaryLight1, 'Light 1'),
                        SizedBox(width: 4.w),
                        _colorShadeBox(settingsState.primaryLight2, 'Light 2'),
                        SizedBox(width: 4.w),
                        _colorShadeBox(settingsState.primaryLight3, 'Light 3'),
                        SizedBox(width: 4.w),
                        _colorShadeBox(settingsState.primaryLight4, 'Light 4'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Paths ExpansionTile
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.all(16.h),
                title: mdTextBold(text: 'Paths'),
                children: [
                  ListTile(
                    title: smText(text: 'Current Directory Path'),
                    subtitle: smText(
                      text:
                          settingsState.directoryPath.isEmpty
                              ? 'Not set'
                              : settingsState.directoryPath,
                    ),
                    trailing: IconButton(
                      icon: AppIcon(
                        defaultIcon: Icons.edit,
                        win11IconPath: ImageAssets.win11EditPencil,
                        size: 20.spMin,
                      ),
                      onPressed: () => _pickNewDirectory(context, ref),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Screen Management ExpansionTile
            ScreenManagementSection(ref: ref),
            SizedBox(height: 16.h),
            // Desktop Side Bar ExpansionTile
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.all(16.h),
                title: mdTextBold(text: 'Desktop Side Bar'),
                children: [
                  CheckboxListTile(
                    title: smText(text: 'Show User Card'),
                    value: settingsState.isShowUserCard,
                    onChanged: (val) {
                      ref.read(settingsProvider.notifier).setShowUserCard(val!);
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState:
                        settingsState.isShowUserCard
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Column(
                      children: [
                        CheckboxListTile(
                          title: smText(text: 'Show Tagline'),
                          value: settingsState.isShowTagLine,
                          onChanged: (val) {
                            ref
                                .read(settingsProvider.notifier)
                                .setShowTagLine(val!);
                          },
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          title: smText(
                            text: 'Show Tagline Instead of CEO Name',
                          ),
                          value: settingsState.isTagLineInsteadOfCEOName,
                          onChanged: (val) {
                            ref
                                .read(settingsProvider.notifier)
                                .setTagLineInsteadOfCEOName(val!);
                          },
                          contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // Elevations ExpansionTile
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                childrenPadding: EdgeInsets.all(16.h),
                title: mdTextBold(text: 'Elevations'),
                children: [
                  ListTile(
                    title: smTextBold(text: 'Card Elevation'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: settingsState.cardElevation,
                          min: 0.0,
                          max: 10.0,
                          divisions: 20,
                          label: settingsState.cardElevation.toStringAsFixed(1),
                          onChanged: (value) {
                            ref
                                .read(settingsProvider.notifier)
                                .setCardElevation(value);
                          },
                        ),
                        smText(
                          text:
                              'Elevation: ${settingsState.cardElevation.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  ListTile(
                    title: smTextBold(text: 'AppBar Elevation'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: settingsState.appBarElevation,
                          min: 0.0,
                          max: 10.0,
                          divisions: 20,
                          label: settingsState.appBarElevation.toStringAsFixed(
                            1,
                          ),
                          onChanged: (value) {
                            ref
                                .read(settingsProvider.notifier)
                                .setAppBarElevation(value);
                          },
                        ),
                        smText(
                          text:
                              'Elevation: ${settingsState.appBarElevation.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  ListTile(
                    title: smTextBold(text: 'Product Card Elevation'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slider(
                          value: settingsState.productCardElevation,
                          min: 0.0,
                          max: 10.0,
                          divisions: 20,
                          label: settingsState.productCardElevation
                              .toStringAsFixed(1),
                          onChanged: (value) {
                            ref
                                .read(settingsProvider.notifier)
                                .setProductCardElevation(value);
                          },
                        ),
                        smText(
                          text:
                              'Elevation: ${settingsState.productCardElevation.toStringAsFixed(1)}',
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallSwitchTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 12.spMin,
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(fontSize: 10.spMin, color: Colors.grey),
              )
              : null,
      trailing: Transform.scale(
        scale: 0.8.spMin,
        child: Switch(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      onTap: () => onChanged(!value),
    );
  }

  String _getBillDesignName(BillDesign design) {
    switch (design) {
      case BillDesign.classic:
        return 'Classic';
      case BillDesign.minimal:
        return 'Minimal';
      case BillDesign.modern:
        return 'Modern';
      case BillDesign.invoice:
        return 'Invoice';
    }
  }

  IconData _getBillDesignIcon(BillDesign design) {
    switch (design) {
      case BillDesign.classic:
        return TablerIcons.file_text;
      case BillDesign.minimal:
        return TablerIcons.file_minus;
      case BillDesign.modern:
        return TablerIcons.file_invoice;
      case BillDesign.invoice:
        return TablerIcons.file_description;
    }
  }

  String _getBillDesignWin11Icon(BillDesign design) {
    switch (design) {
      case BillDesign.classic:
        return ImageAssets.win11Doc1;
      case BillDesign.minimal:
        return ImageAssets.win11Doc2;
      case BillDesign.modern:
        return ImageAssets.win11Doc3;
      case BillDesign.invoice:
        return ImageAssets.win11Invoice;
    }
  }

  String _getThermalDesignName(ThermalDesign design) {
    switch (design) {
      case ThermalDesign.classic:
        return 'Classic';
      case ThermalDesign.minimal:
        return 'Minimal';
    }
  }

  IconData _getThermalDesignIcon(ThermalDesign design) {
    switch (design) {
      case ThermalDesign.classic:
        return TablerIcons.receipt;
      case ThermalDesign.minimal:
        return TablerIcons.receipt_off;
    }
  }

  void _showPaidStampConfigDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settingsState,
  ) {
    final textController = TextEditingController(
      text: settingsState.paidStampText,
    );
    final signatureController = TextEditingController(
      text: settingsState.paidStampSignature,
    );
    bool showDate = settingsState.showDateOnStamp;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: mdTextBold(text: 'Configure Paid Stamp'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Customize how the paid stamp appears on your bills',
                          style: TextStyle(
                            fontSize: 12.spMin,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextField(
                          controller: textController,
                          decoration: InputDecoration(
                            labelText: 'Stamp Text',
                            hintText: 'e.g., PAID, RECEIVED',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: signatureController,
                          decoration: InputDecoration(
                            labelText: 'Signature / Authorized By',
                            hintText: 'e.g., Manager Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Show Date on Stamp',
                            style: TextStyle(fontSize: 14.spMin),
                          ),
                          value: showDate,
                          onChanged: (val) {
                            setState(() {
                              showDate = val ?? true;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.spMin),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final notifier = ref.read(settingsProvider.notifier);
                        notifier.setShowPaidStamp(true);
                        notifier.setPaidStampText(
                          textController.text.isEmpty
                              ? 'PAID'
                              : textController.text,
                        );
                        notifier.setPaidStampSignature(
                          signatureController.text,
                        );
                        notifier.setShowDateOnStamp(showDate);
                        Navigator.pop(ctx);
                        AppFlushbar.success(
                          context,
                          message: 'Paid stamp configured successfully',
                        );
                      },
                      child: Text('Save', style: TextStyle(fontSize: 14.spMin)),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showWatermarkConfigDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settingsState,
  ) {
    double opacity = settingsState.watermarkOpacity;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: mdTextBold(text: 'Paid Stamp Watermark'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shows paid stamp image as background watermark on paid bills',
                          style: TextStyle(
                            fontSize: 12.spMin,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Opacity: ${(opacity * 100).toInt()}%',
                          style: TextStyle(fontSize: 12.spMin),
                        ),
                        Slider(
                          value: opacity,
                          min: 0.05,
                          max: 0.50,
                          divisions: 45,
                          label: '${(opacity * 100).toInt()}%',
                          onChanged: (val) {
                            setState(() {
                              opacity = val;
                            });
                          },
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: double.infinity,
                          height: 100.h,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8.r),
                            color: Colors.grey.shade50,
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Text(
                                  'Bill Content',
                                  style: TextStyle(
                                    fontSize: 12.spMin,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              Center(
                                child: Transform.rotate(
                                  angle: -0.3,
                                  child: Opacity(
                                    opacity: opacity,
                                    child: Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.green.shade700,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          4.r,
                                        ),
                                      ),
                                      child: Text(
                                        'PAID',
                                        style: TextStyle(
                                          fontSize: 20.spMin,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Uses "paid stamp.png" from assets folder',
                          style: TextStyle(
                            fontSize: 10.spMin,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 14.spMin),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final notifier = ref.read(settingsProvider.notifier);
                        notifier.setShowBackgroundWatermark(true);
                        notifier.setWatermarkOpacity(opacity);
                        Navigator.pop(ctx);
                        AppFlushbar.success(
                          context,
                          message: 'Watermark configured successfully',
                        );
                      },
                      child: Text('Save', style: TextStyle(fontSize: 14.spMin)),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _colorShadeBox(Color color, String label, {bool isMain = false}) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: Container(
          height: isMain ? 36.h : 30.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4.r),
            border: isMain ? Border.all(color: Colors.black, width: 2) : null,
          ),
        ),
      ),
    );
  }
}
