// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:desktopapp/res/assets/image_assets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:open_file/open_file.dart';
import '../../models/bills_model.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../view_models/providers/bills_provider.dart';
import '../../view_models/providers/profile_provider.dart';
import '../../view_models/services/database/database_services.dart'
    hide databaseServiceProvider;
import '../home/rapper.dart';
import 'edit_bill.dart';
import 'widgets/pdf_genrater_widget.dart';
import 'widgets/thermal_print_widget.dart';
import '../../view_models/providers/add_prduct_provider.dart';
import '../../view_models/providers/bill_detail_provider.dart';
import '../../view_models/providers/settings_provider.dart';

class BillDetailScreen extends ConsumerStatefulWidget {
  final Bill bill;

  const BillDetailScreen({super.key, required this.bill});

  @override
  BillDetailScreenState createState() => BillDetailScreenState();
}

class BillDetailScreenState extends ConsumerState<BillDetailScreen> {
  late HiveService _hiveService;

  Future<void> _initializeSettings() async {
    await _hiveService.init();
    await _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    await ref.read(billDetailProvider(widget.bill).notifier).loadCustomer();
  }

  @override
  void initState() {
    super.initState();
    _hiveService = HiveService();
    _initializeSettings();
    _loadDefaultLogo();
  }

  Future<void> _loadDefaultLogo() async {
    try {
      // Logo loading logic if needed
    } catch (e) {
      // Proceed without logo
    }
  }

  Future<void> _generateAndSavePDF(Bill bill, String shopName) async {
    // Load user profile data from database
    final dbService = ref.read(databaseServiceProvider);
    final users = await dbService.getUsers();
    final settingsState = ref.read(settingsProvider);

    Uint8List? shopLogo;
    String? ownerName;
    String? phoneNumber;
    String? email;
    String? tagline;
    String? shopAddress;
    String? customerPhone;
    String? bankName;
    String? accountNumber;
    String? ifscCode;
    Uint8List? bankQrCode;

    // Contact & social media icons
    Uint8List? phoneIcon;
    Uint8List? emailIcon;
    Map<String, String>? socialMediaHandles;
    Uint8List? facebookIcon;
    Uint8List? instagramIcon;
    Uint8List? twitterIcon;
    Uint8List? whatsappIcon;

    // Fetch customer phone from customer record
    if (bill.customerId != null && bill.customerId!.isNotEmpty) {
      final customers = await dbService.getCustomers();
      final customer =
          customers.where((c) => c.id == bill.customerId).firstOrNull;
      if (customer != null && customer.phoneNumber.isNotEmpty) {
        customerPhone = customer.phoneNumber;
      }
    }

    if (users.isNotEmpty) {
      final user = users.first;
      ownerName = user.ownerName;
      phoneNumber = user.phoneNumber;
      email = user.email;
      tagline = user.shopTagline;
      shopAddress = user.shopAddress;

      // Load shop logo if exists
      if (user.shopLogoPath != null && user.shopLogoPath!.isNotEmpty) {
        final logoFile = File(user.shopLogoPath!);
        if (await logoFile.exists()) {
          shopLogo = await logoFile.readAsBytes();
        }
      }

      // Load bank details based on settings (if enabled and bank exists)
      if (settingsState.showBankDetailsOnBill && user.bankDetails.isNotEmpty) {
        // Use selected bank index from settings, fallback to first bank
        final bankIndex = settingsState.selectedBankIndex.clamp(
          0,
          user.bankDetails.length - 1,
        );
        final selectedBank = user.bankDetails[bankIndex];
        bankName = selectedBank.bankName;
        accountNumber = selectedBank.accountNumber;
        ifscCode = selectedBank.ifscCode;

        // Load bank QR code if exists
        if (selectedBank.qrCodePath != null &&
            selectedBank.qrCodePath!.isNotEmpty) {
          final qrFile = File(selectedBank.qrCodePath!);
          if (await qrFile.exists()) {
            bankQrCode = await qrFile.readAsBytes();
          }
        }
      }

      // Load social media handles from user profile
      socialMediaHandles = {};
      if (user.facebook != null && user.facebook!.isNotEmpty) {
        socialMediaHandles['facebook'] = user.facebook!;
      }
      if (user.instagram != null && user.instagram!.isNotEmpty) {
        socialMediaHandles['instagram'] = user.instagram!;
      }
      if (user.twitter != null && user.twitter!.isNotEmpty) {
        socialMediaHandles['twitter'] = user.twitter!;
      }
      if (user.whatsapp != null && user.whatsapp!.isNotEmpty) {
        socialMediaHandles['whatsapp'] = user.whatsapp!;
      }
    }

    // Load watermark image from assets if watermark is enabled
    Uint8List? watermarkImage;
    if (settingsState.showBackgroundWatermark) {
      try {
        final byteData = await rootBundle.load('assets/paid stamp.png');
        watermarkImage = byteData.buffer.asUint8List();
      } catch (e) {
        debugPrint('Error loading watermark image: $e');
      }
    }

    // Load social media icons from assets (for modern & invoice design)
    final needsIcons = settingsState.billDesign == BillDesign.modern ||
        settingsState.billDesign == BillDesign.invoice;
    if (needsIcons) {
      try {
        // Phone & email icons (for invoice sidebar)
        if (settingsState.billDesign == BillDesign.invoice) {
          final phoneData = await rootBundle.load('assets/win_11/phone-48.png');
          phoneIcon = phoneData.buffer.asUint8List();
          final emailData = await rootBundle.load('assets/win_11/email-48.png');
          emailIcon = emailData.buffer.asUint8List();
        }
        // Social media icons
        if (socialMediaHandles != null && socialMediaHandles.isNotEmpty) {
          if (socialMediaHandles.containsKey('facebook')) {
            final data = settingsState.billDesign == BillDesign.invoice
                ? await rootBundle.load('assets/win_11/facebook-48.png')
                : await rootBundle.load('assets/icons8-facebook-96.png');
            facebookIcon = data.buffer.asUint8List();
          }
          if (socialMediaHandles.containsKey('instagram')) {
            final data = settingsState.billDesign == BillDesign.invoice
                ? await rootBundle.load('assets/win_11/instagram-48.png')
                : await rootBundle.load('assets/instagram-.png');
            instagramIcon = data.buffer.asUint8List();
          }
          if (socialMediaHandles.containsKey('twitter')) {
            final data = settingsState.billDesign == BillDesign.invoice
                ? await rootBundle.load('assets/win_11/x-48.png')
                : await rootBundle.load('assets/x.png');
            twitterIcon = data.buffer.asUint8List();
          }
          if (socialMediaHandles.containsKey('whatsapp')) {
            final data = settingsState.billDesign == BillDesign.invoice
                ? await rootBundle.load('assets/win_11/whatsapp-48.png')
                : await rootBundle.load('assets/whatsapp.png');
            whatsappIcon = data.buffer.asUint8List();
          }
        }
      } catch (e) {
        debugPrint('Error loading icons: $e');
      }
    }

    final pdfGenerator = ReceiptPDFGenerator(
      bill: bill,
      shopName: shopName,
      shopLogo: shopLogo,
      ownerName: ownerName,
      phoneNumber: phoneNumber,
      email: email,
      tagline: tagline,
      shopAddress: shopAddress,
      customerPhone: customerPhone,
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      bankQrCode: bankQrCode,
      billDesign: settingsState.billDesign,
      showPaidStamp: settingsState.showPaidStamp,
      paidStampText: settingsState.paidStampText,
      paidStampSignature: settingsState.paidStampSignature,
      showDateOnStamp: settingsState.showDateOnStamp,
      showBackgroundWatermark: settingsState.showBackgroundWatermark,
      watermarkOpacity: settingsState.watermarkOpacity,
      watermarkImage: watermarkImage,
      socialMediaHandles: socialMediaHandles,
      phoneIcon: phoneIcon,
      emailIcon: emailIcon,
      facebookIcon: facebookIcon,
      instagramIcon: instagramIcon,
      twitterIcon: twitterIcon,
      whatsappIcon: whatsappIcon,
    );
    final pdf = pdfGenerator.generatePDF();

    final directoryPath = await HiveService().directoryPath;
    final directory = Directory('$directoryPath/invoices');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final file = File(
      '$directoryPath/invoices/invoice_${bill.id.substring(0, 8)}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  Future<void> _deleteBill() async {
    await ref.read(databaseServiceProvider).deleteBill(widget.bill.id);
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(billsProvider.notifier).fetchBills();
      });
      Navigator.pop(context);
    }
  }

  Future<void> _showPrinterSelectionDialog() async {
    await ref.read(billDetailProvider(widget.bill).notifier).scanForPrinters();

    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (ctx) => Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(billDetailProvider(widget.bill));
              return AlertDialog(
                title: Text(
                  'Select Thermal Printer',
                  style: TextStyle(fontSize: 16.spMin),
                ),
                content: SizedBox(
                  width: 300.w,
                  child:
                      state.printers.isEmpty
                          ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16.h),
                              Text(
                                'Scanning for USB printers...',
                                style: TextStyle(fontSize: 14.spMin),
                              ),
                            ],
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            itemCount: state.printers.length,
                            itemBuilder: (context, index) {
                              final printer = state.printers[index];
                              final isSelected =
                                  state.selectedPrinter?.name == printer.name;
                              return ListTile(
                                leading: AppIcon(
                                  defaultIcon: Icons.print,
                                  win11IconPath: ImageAssets.win11Print,
                                  color: isSelected ? AppColors.primary : null,
                                ),
                                title: Text(
                                  printer.name,
                                  style: TextStyle(
                                    fontSize: 14.spMin,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                                trailing:
                                    isSelected
                                        ? AppIcon(
                                          defaultIcon: Icons.check,
                                          win11IconPath: ImageAssets.win11Done,
                                          color: AppColors.primary,
                                        )
                                        : null,
                                onTap: () {
                                  ref
                                      .read(
                                        billDetailProvider(
                                          widget.bill,
                                        ).notifier,
                                      )
                                      .selectPrinter(printer);
                                  Navigator.pop(ctx);
                                  AppFlushbar.success(
                                    context,
                                    message:
                                        'Printer selected: ${printer.name}',
                                  );
                                },
                              );
                            },
                          ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: TextStyle(fontSize: 14.spMin)),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ref
                          .read(billDetailProvider(widget.bill).notifier)
                          .scanForPrinters();
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
    );
  }

  Future<void> _printThermal() async {
    final state = ref.read(billDetailProvider(widget.bill));
    final settingsState = ref.read(settingsProvider);

    if (state.selectedPrinter == null) {
      AppFlushbar.warning(
        context,
        message: 'Please select a thermal printer first',
      );
      await _showPrinterSelectionDialog();
      return;
    }

    ref.read(billDetailProvider(widget.bill).notifier).setPrintingThermal(true);

    // Load shop info for thermal receipt
    final dbService = ref.read(databaseServiceProvider);
    final users = await dbService.getUsers();
    String? shopName;
    Uint8List? shopLogo;

    if (users.isNotEmpty) {
      final user = users.first;
      shopName = user.shopName;
      if (user.shopLogoPath != null && user.shopLogoPath!.isNotEmpty) {
        final logoFile = File(user.shopLogoPath!);
        if (await logoFile.exists()) {
          shopLogo = await logoFile.readAsBytes();
        }
      }
    }

    final thermalPrinter = ThermalReceiptPrinter(
      bill: widget.bill,
      context: context,
      design: settingsState.thermalDesign,
      shopName: shopName,
      shopLogo: shopLogo,
    );

    await thermalPrinter.printThermal(state.selectedPrinter, () {
      if (mounted) {
        ref
            .read(billDetailProvider(widget.bill).notifier)
            .setPrintingThermal(false);
        AppFlushbar.success(context, message: 'Receipt printed successfully');
      }
    });
  }

  // Function to handle biometric authentication
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
          localizedReason: 'Authenticate to edit or delete the bill',
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
                        title: Text(
                          'Enter PIN to Authenticate',
                          style: TextStyle(fontSize: 18.spMin),
                        ),
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

  Widget _buildHeader() {
    final state = ref.watch(billDetailProvider(widget.bill));

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 12.w),
        child: Column(
          spacing: 6.h,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mdTextBold(text: 'General Information'),
            SizedBox(height: 3.h),
            MainTxtRow(val: widget.bill.id, txt: 'Bill ID:'),
            MainTxtRow(
              val: DateFormat('dd/MM/yyyy HH:mm').format(widget.bill.dateTime),
              txt: 'Date:',
            ),
            MainTxtRow(
              val: widget.bill.customerName ?? "Walk-in",
              txt: 'Name:',
            ),
            MainTxtRow(val: state.customer?.phoneNumber ?? "", txt: 'Phone:'),
            MainTxtRow(val: state.customer?.address ?? "", txt: 'Address:'),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingSummary() {
    final discount = widget.bill.discount;
    final totalAfterDiscount = widget.bill.totalAmount - discount;
    final paidAmount = widget.bill.paidAmount;
    final pendingAmount =
        totalAfterDiscount - paidAmount > 0
            ? totalAfterDiscount - paidAmount
            : 0.0;

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 12.w),
        child: Column(
          spacing: 6.h,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mdTextBold(text: 'Billing Summary'),
            SizedBox(height: 3.h),
            MainTxtRow(
              val: totalAfterDiscount.toStringAsFixed(2),
              txt: 'Total:',
            ),
            MainTxtRow(val: paidAmount.toStringAsFixed(2), txt: 'Paid Amount:'),
            MainTxtRow(
              valWidget: mdTextBold(
                text: 'Rs.${pendingAmount.toStringAsFixed(2)}',
                color: pendingAmount > 0 ? Colors.orange : Colors.green,
              ),
              txt: 'Pending Amount:',
            ),
            MainTxtRow(
              valWidget: Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color:
                      widget.bill.status == 'Paid'
                          ? Colors.green.withValues(alpha: 0.1)
                          : widget.bill.status == 'Pending'
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: mdText(
                  text: widget.bill.status,
                  color:
                      widget.bill.status == 'Paid'
                          ? Colors.green
                          : widget.bill.status == 'Pending'
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
              txt: 'Status:',
            ),
            if (widget.bill.paymentMethod != null) ...[
              MainTxtRow(
                val: widget.bill.paymentMethod!,
                txt: 'Payment Method:',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable2() {
    final discount = widget.bill.discount;
    final totalAfterDiscount = widget.bill.totalAmount - discount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.spMin, horizontal: 12.spMin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mdTextBold(text: 'Items'),
            SizedBox(height: 14.spMin),
            // Modern table: rounded, bordered, header + zebra rows + summary.
            ClipRRect(
              borderRadius: BorderRadius.circular(12.spMin),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.spMin),
                  border: Border.all(
                    color:
                        isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppColors.border,
                  ),
                ),
                child: Column(
                  children: [
                    _tableHeader(isDark),
                    // Item rows (zebra striping for readability).
                    ...List.generate(widget.bill.items.length, (index) {
                      final item = widget.bill.items[index];
                      final qty = widget.bill.quantities[item.id] ?? 1;
                      final itemTotal = item.price * qty;
                      return _itemRow(
                        isDark: isDark,
                        striped: index.isOdd,
                        name: item.name,
                        qty: qty.toString(),
                        unitPrice: 'Rs.${item.price.toStringAsFixed(2)}',
                        total: 'Rs.${itemTotal.toStringAsFixed(2)}',
                      );
                    }),
                    // Summary block, visually separated from the item rows.
                    Divider(
                      height: 1,
                      thickness: 1,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.border,
                    ),
                    _summaryRow(
                      isDark: isDark,
                      label: 'Subtotal',
                      value: 'Rs.${widget.bill.totalAmount.toStringAsFixed(2)}',
                    ),
                    if (discount > 0)
                      _summaryRow(
                        isDark: isDark,
                        label: 'Discount',
                        value: '-Rs.${discount.toStringAsFixed(2)}',
                        valueColor: AppColors.error,
                      ),
                    _summaryRow(
                      isDark: isDark,
                      label: 'Total',
                      value: 'Rs.${totalAfterDiscount.toStringAsFixed(2)}',
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Modern items-table pieces ----------------------------------------

  Widget _tableHeader(bool isDark) {
    return Container(
      color: isDark ? AppColors.primary.withValues(alpha: 0.22) : AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: 14.spMin, vertical: 12.spMin),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: _headCell('Name', Colors.white, TextAlign.left),
          ),
          Expanded(
            flex: 2,
            child: _headCell('Qty', Colors.white, TextAlign.center),
          ),
          Expanded(
            flex: 3,
            child: _headCell('Unit Price', Colors.white, TextAlign.right),
          ),
          Expanded(
            flex: 3,
            child: _headCell('Total', Colors.white, TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _headCell(String text, Color color, TextAlign align) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 12.spMin,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _itemRow({
    required bool isDark,
    required bool striped,
    required String name,
    required String qty,
    required String unitPrice,
    required String total,
  }) {
    final stripeColor =
        isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.025);
    return Container(
      color: striped ? stripeColor : Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 14.spMin, vertical: 12.spMin),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              name,
              style: TextStyle(fontSize: 12.spMin),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              qty,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.spMin),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              unitPrice,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.spMin,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              total,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.spMin,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required bool isDark,
    required String label,
    required String value,
    Color? valueColor,
    bool emphasize = false,
  }) {
    return Container(
      color:
          isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
      padding: EdgeInsets.symmetric(
        horizontal: 14.spMin,
        vertical: emphasize ? 14.spMin : 11.spMin,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 14.spMin : 12.spMin,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
              color: emphasize ? AppColors.primary : null,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 15.spMin : 12.spMin,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (emphasize ? AppColors.primary : null),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnimatedEntry(delayMs: 0, child: _buildHeader()),
          SizedBox(height: 16.h),
          _AnimatedEntry(delayMs: 90, child: _buildBillingSummary()),
          SizedBox(height: 16.h),
          _AnimatedEntry(delayMs: 180, child: _buildDataTable2()),
        ],
      ),
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AnimatedEntry(delayMs: 0, child: _buildHeader()),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _AnimatedEntry(
                  delayMs: 90,
                  child: _buildBillingSummary(),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _AnimatedEntry(delayMs: 180, child: _buildDataTable2()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.read(profileProvider);
    final shopName = profileState.shopName ?? 'Your Shop';

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Bill #${widget.bill.id}',
        context: context,
        actions: [
          DropdownButton<String>(
            padding: EdgeInsets.zero,

            focusColor: Colors.transparent,
            icon: AppIcon(
              defaultIcon: Icons.more_vert,
              win11IconPath: ImageAssets.win11MenuVertical,
              size: 20.spMin,
            ),
            underline: SizedBox(),
            items: [
              DropdownMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    AppIcon(
                      defaultIcon: Icons.edit,
                      win11IconPath: ImageAssets.win11EditPencil,
                      size: 16.spMin,
                    ),
                    SizedBox(width: 8.w),
                    smText(text: 'Edit Bill'),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    AppIcon(
                      defaultIcon: Icons.delete,
                      win11IconPath: ImageAssets.win11RecycleBin,
                      size: 16.spMin,
                      color: Colors.red,
                    ),
                    SizedBox(width: 8.w),
                    smText(text: 'Delete Bill', color: Colors.red),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'save_pdf',
                child: Row(
                  children: [
                    AppIcon(
                      defaultIcon: Icons.picture_as_pdf,
                      win11IconPath: ImageAssets.win11Pdf,
                      size: 16.spMin,
                    ),
                    SizedBox(width: 8.w),
                    smText(text: 'Save as PDF'),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'select_printer',
                child: Row(
                  children: [
                    AppIcon(
                      defaultIcon: Icons.print_outlined,
                      win11IconPath: ImageAssets.win11Print,
                      size: 16.spMin,
                    ),
                    SizedBox(width: 8.w),
                    smText(text: 'Select Printer'),
                  ],
                ),
              ),
              DropdownMenuItem<String>(
                value: 'print_thermal',
                child: Row(
                  children: [
                    AppIcon(
                      defaultIcon: Icons.receipt_long,
                      win11IconPath: ImageAssets.win11Print,
                      size: 16.spMin,
                    ),
                    SizedBox(width: 8.w),
                    smText(text: 'Print Thermal'),
                  ],
                ),
              ),
            ],
            onChanged: (value) async {
              if (value == 'edit') {
                // Require biometric authentication for editing
                final authenticated = await _authenticate(context);
                if (authenticated) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditBillScreen(bill: widget.bill),
                    ),
                  );
                }
              } else if (value == 'delete') {
                // Require biometric authentication for deleting
                final authenticated = await _authenticate(context);
                if (authenticated) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: mdTextBold(text: 'Delete Bill'),
                          content: mdText(
                            text: 'Are you sure you want to delete this bill?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: smText(text: 'Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: smText(text: 'Delete', color: Colors.red),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await _deleteBill();
                  }
                } else {
                  AppFlushbar.error(context, message: 'Authentication failed');
                }
              } else if (value == 'save_pdf') {
                await _generateAndSavePDF(widget.bill, shopName);
              } else if (value == 'select_printer') {
                await _showPrinterSelectionDialog();
              } else if (value == 'print_thermal') {
                await _printThermal();
              }
            },
          ),
        ],
      ),
      body: ResponsiveWrapper(
        mobile: _buildMobileView(),
        tablet: _buildMobileView(),
        desktop: _buildDesktopView(),
      ),
    );
  }
}

/// One-shot entrance animation (fade + slide up) that plays when the widget
/// first builds — a *page* animation, not tied to scrolling. [delayMs] staggers
/// multiple entries so sections cascade in.
class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _AnimatedEntry({required this.child, this.delayMs = 0});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    // Stagger the start so sections cascade in on page open.
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class TxtRow extends StatelessWidget {
  const TxtRow({super.key, required this.txt});

  final String txt;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 2.w,
      children: [
        AppIcon(
          defaultIcon: TablerIcons.point_filled,
          win11IconPath: ImageAssets.win11FilledCircle,
          size: 18.spMin,
        ),
        mdText(text: txt),
      ],
    );
  }
}

class MainTxtRow extends StatelessWidget {
  const MainTxtRow({super.key, required this.txt, this.val, this.valWidget});

  final String txt;
  final String? val;
  final Widget? valWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 2.w,
      children: [TxtRow(txt: txt), valWidget ?? mdTextBold(text: val ?? "")],
    );
  }
}
