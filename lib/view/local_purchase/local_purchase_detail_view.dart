import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import '../../models/local_purchase_model.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_button.dart';
import '../../res/components/app_flushbar.dart';
import '../../utils/app_sizes.dart';
import '../../view_models/providers/local_purchase_provider.dart';
import '../../view_models/providers/profile_provider.dart';
import '../../view_models/services/keyboard/app_keyboard_service.dart';
import 'local_purchase_form_view.dart';
import 'local_purchase_pdf_generator.dart';

class LocalPurchaseDetailView extends ConsumerStatefulWidget {
  final LocalPurchaseAgreement agreement;
  final bool autoPrint;

  const LocalPurchaseDetailView({
    super.key,
    required this.agreement,
    this.autoPrint = false,
  });

  @override
  ConsumerState<LocalPurchaseDetailView> createState() =>
      _LocalPurchaseDetailViewState();
}

class _LocalPurchaseDetailViewState
    extends ConsumerState<LocalPurchaseDetailView> {
  bool _isActionInProgress = false;

  /// Ctrl+P prints the agreement — handled by the window-level keyboard
  /// dispatcher (see [AppKeyboardScope]) — focus-independent.
  late final AppKeyboardScope _keys = AppKeyboardScope('purchase-detail', (
    event,
  ) {
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyP, ctrl: true)) {
      _printAgreement();
      return true;
    }
    return false;
  });

  @override
  void initState() {
    super.initState();
    AppKeyboardScope.register(_keys);
    if (widget.autoPrint) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _printAgreement();
      });
    }
  }

  @override
  void dispose() {
    AppKeyboardScope.unregister(_keys);
    super.dispose();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        AppFlushbar.error(context, message: 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<Uint8List> _generatePdfBytes() async {
    final profile = ref.read(profileProvider);
    Uint8List? logoBytes;
    if (profile.shopLogo != null && await profile.shopLogo!.exists()) {
      logoBytes = await profile.shopLogo!.readAsBytes();
    }
    final generator = LocalPurchasePDFGenerator(
      agreement: widget.agreement,
      shopName: profile.shopName ?? 'My Shop',
      ownerName: profile.ownerName,
      shopAddress: profile.shopAddress,
      shopPhone: profile.phoneNumber,
      shopLogo: logoBytes,
    );
    return await generator.generatePDF().save();
  }

  Future<void> _printAgreement() async {
    await _runAction(() async {
      final bytes = await _generatePdfBytes();
      await Printing.layoutPdf(onLayout: (_) => bytes);
    });
  }

  Future<void> _savePdf() async {
    await _runAction(() async {
      final bytes = await _generatePdfBytes();
      final dir = await getApplicationDocumentsDirectory();
      final invoicesDir = Directory('${dir.path}/invoices');
      if (!await invoicesDir.exists()) {
        await invoicesDir.create(recursive: true);
      }
      final fileName =
          'purchase_${widget.agreement.id.substring(0, 8)}_${DateFormat('yyyyMMdd').format(widget.agreement.dateTime)}.pdf';
      final file = File('${invoicesDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        AppFlushbar.success(context, message: 'PDF saved: $fileName');
        await OpenFile.open(file.path);
      }
    });
  }

  Future<void> _sharePdf() async {
    await _runAction(() async {
      final bytes = await _generatePdfBytes();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'purchase_${widget.agreement.id.substring(0, 8)}.pdf',
      );
    });
  }

  void _editAgreement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalPurchaseFormView(agreement: widget.agreement),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Agreement'),
            content: const Text(
              'Are you sure you want to delete this purchase agreement?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(localPurchaseProvider.notifier)
                      .deleteAgreement(widget.agreement.id);
                  if (mounted) {
                    AppFlushbar.success(context, message: 'Agreement deleted.');
                    Navigator.pop(context);
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.agreement;
    final isDesktop = AppSizes.isDesktop(context);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Purchase Agreement',
        context: context,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: _editAgreement,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'print':
                  _printAgreement();
                case 'save':
                  _savePdf();
                case 'share':
                  _sharePdf();
                case 'delete':
                  _confirmDelete();
              }
            },
            itemBuilder:
                (ctx) => [
                  const PopupMenuItem(
                    value: 'print',
                    child: Row(
                      children: [
                        Icon(Icons.print),
                        SizedBox(width: 8),
                        Text('Print'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'save',
                    child: Row(
                      children: [
                        Icon(Icons.save_alt),
                        SizedBox(width: 8),
                        Text('Save PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24.w : 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(a),
            SizedBox(height: 16.h),
            _buildSellerCard(a),
            SizedBox(height: 16.h),
            _buildItemsCard(a),
            SizedBox(height: 16.h),
            _buildPaymentCard(a),
            SizedBox(height: 16.h),
            _buildTermsCard(a),
            SizedBox(height: 16.h),
            _buildSignaturesCard(a),
            if (a.notes != null && a.notes!.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildNotesCard(a),
            ],
            SizedBox(height: 32.h),
          ],
        ),
      ),
      bottomNavigationBar:
          AppSizes.isDesktop(context) ? null : _buildMobileActionBar(),
    );
  }

  Widget _buildHeaderCard(LocalPurchaseAgreement a) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.spMin),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agreement #${a.id.substring(0, 8)}',
                  style: TextStyle(
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(a.dateTime),
                  style: TextStyle(fontSize: 12.spMin, color: Colors.grey[600]),
                ),
              ],
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                a.paymentType,
                style: TextStyle(
                  fontSize: 12.spMin,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerCard(LocalPurchaseAgreement a) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.spMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seller Details',
              style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold),
            ),
            Divider(height: 16.h),
            _detailRow('Name', a.sellerName),
            if (a.sellerPhone != null) _detailRow('Phone', a.sellerPhone!),
            if (a.sellerIdCard != null) _detailRow('ID Card', a.sellerIdCard!),
            if (a.sellerAddress != null)
              _detailRow('Address', a.sellerAddress!),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(LocalPurchaseAgreement a) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.spMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items',
              style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold),
            ),
            Divider(height: 16.h),
            ...a.items.map(
              (item) => Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.name,
                        style: TextStyle(fontSize: 12.spMin),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${item.quantity}x',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.spMin),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Rs.${item.unitPrice.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 12.spMin),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Rs.${item.totalPrice.toStringAsFixed(0)}',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12.spMin,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rs.${a.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16.spMin,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(LocalPurchaseAgreement a) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.spMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment',
              style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold),
            ),
            Divider(height: 16.h),
            _detailRow('Type', a.paymentType),
            _detailRow('Amount', 'Rs.${a.totalAmount.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCard(LocalPurchaseAgreement a) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.spMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
              style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold),
            ),
            Divider(height: 16.h),
            ...a.termsAndConditions.map(
              (term) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  term,
                  style: TextStyle(fontSize: 11.spMin, color: Colors.grey[700]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignaturesCard(LocalPurchaseAgreement a) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.spMin),
        child: Row(
          children: [
            Expanded(
              child: _signatureBlock(
                'Seller Signature',
                a.sellerSignature ?? '_________________',
              ),
            ),
            SizedBox(width: 24.w),
            Expanded(
              child: _signatureBlock(
                'Owner Signature',
                a.ownerSignature ?? '_________________',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signatureBlock(String label, String signature) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          signature,
          style: TextStyle(fontSize: 12.spMin, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Container(height: 1, color: Colors.grey),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 10.spMin, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildNotesCard(LocalPurchaseAgreement a) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.spMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold),
            ),
            Divider(height: 16.h),
            Text(
              a.notes!,
              style: TextStyle(fontSize: 12.spMin, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.spMin,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12.spMin))),
        ],
      ),
    );
  }

  Widget _buildMobileActionBar() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton().primaryButton(
                text: 'Print',
                onPressed: _printAgreement,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _savePdf,
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text('Save PDF'),
              ),
            ),
            SizedBox(width: 8.w),
            IconButton(
              onPressed: _sharePdf,
              icon: const Icon(Icons.share),
              tooltip: 'Share',
            ),
          ],
        ),
      ),
    );
  }
}
