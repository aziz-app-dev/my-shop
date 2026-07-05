// ignore_for_file: unused_local_variable

import 'dart:typed_data';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/bills_model.dart';
import '../../../view_models/providers/settings_provider.dart';

class ReceiptPDFGenerator {
  final Bill bill;
  final String shopName;
  final Uint8List? shopLogo;
  final String? ownerName;
  final String? phoneNumber;
  final String? email;
  final String? tagline;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final Uint8List? bankQrCode;
  final BillDesign billDesign;
  // Paid stamp settings
  final bool showPaidStamp;
  final String paidStampText;
  final String paidStampSignature;
  final bool showDateOnStamp;
  // Background watermark settings (uses paid stamp image from assets)
  final bool showBackgroundWatermark;
  final double watermarkOpacity;
  final Uint8List? watermarkImage; // PNG image for watermark stamp
  // Modern design extras
  final String? shopAddress;
  final String? shopCity;
  final String? customerPhone;
  final List<String>? termsAndConditions;
  final Map<String, String>?
  socialMediaHandles; // e.g., {'facebook': 'mypage', 'instagram': 'myinsta'}
  // Contact icons (optional PNG images)
  final Uint8List? phoneIcon;
  final Uint8List? emailIcon;
  // Social media icons (optional PNG images)
  final Uint8List? facebookIcon;
  final Uint8List? instagramIcon;
  final Uint8List? twitterIcon;
  final Uint8List? whatsappIcon;
  final Uint8List? youtubeIcon;

  ReceiptPDFGenerator({
    required this.bill,
    required this.shopName,
    this.shopLogo,
    this.ownerName,
    this.phoneNumber,
    this.email,
    this.tagline,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.bankQrCode,
    this.billDesign = BillDesign.classic,
    this.showPaidStamp = false,
    this.paidStampText = 'PAID',
    this.paidStampSignature = '',
    this.showDateOnStamp = true,
    this.showBackgroundWatermark = false,
    this.watermarkOpacity = 0.15,
    this.watermarkImage,
    this.shopAddress,
    this.shopCity,
    this.customerPhone,
    this.termsAndConditions = const [
      '1. Items purchased are non-refundable.',
      '2. Warranty available for 6 Months on selected items.',
      '3. Damage & Burned claim not acceptable.',
      '4. China items no claim no Warranty.',
    ],
    this.socialMediaHandles,
    this.phoneIcon,
    this.emailIcon,
    this.facebookIcon,
    this.instagramIcon,
    this.twitterIcon,
    this.whatsappIcon,
    this.youtubeIcon,
  });

  pw.Document generatePDF() {
    final pdf = pw.Document();

    // Use A4 for modern/invoice design, roll80 for classic/minimal
    final pageFormat =
        (billDesign == BillDesign.modern || billDesign == BillDesign.invoice)
            ? PdfPageFormat.a4
            : PdfPageFormat.roll80;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin:
            (billDesign == BillDesign.modern ||
                    billDesign == BillDesign.invoice)
                ? const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15)
                : null,
        build: (pw.Context context) => _buildPageWithWatermark(pageFormat),
      ),
    );

    return pdf;
  }

  /// Builds the page content with optional watermark overlay (paid stamp image)
  pw.Widget _buildPageWithWatermark(PdfPageFormat pageFormat) {
    final content = _buildPDFContent();

    // Only show watermark if enabled, bill is paid, and image is provided
    if (!showBackgroundWatermark ||
        bill.status != 'Paid' ||
        watermarkImage == null) {
      return content;
    }

    // Calculate watermark size based on page format
    final isA4 =
        billDesign == BillDesign.modern || billDesign == BillDesign.invoice;
    final imageSize =
        isA4 ? 80.0 : 50.0; // Smaller size for positioning near date

    return pw.Stack(
      children: [
        // Main content layer
        content,
        // Watermark positioned near the date area (top-right for modern, top for classic/minimal)
        if (isA4)
          pw.Positioned(
            top: 130, // Position near the invoice details section
            right: 30,
            child: pw.Opacity(
              opacity: watermarkOpacity,
              child: pw.Transform.rotate(
                angle: -0.2, // Slight tilt
                child: pw.Image(
                  pw.MemoryImage(watermarkImage!),
                  width: imageSize,
                  height: imageSize,
                ),
              ),
            ),
          )
        else
          pw.Positioned(
            top: 60, // Position near the date/invoice info for receipt
            right: 5,
            child: pw.Opacity(
              opacity: watermarkOpacity,
              child: pw.Transform.rotate(
                angle: -0.2,
                child: pw.Image(
                  pw.MemoryImage(watermarkImage!),
                  width: imageSize,
                  height: imageSize,
                ),
              ),
            ),
          ),
      ],
    );
  }

  pw.Widget _buildPDFContent() {
    switch (billDesign) {
      case BillDesign.classic:
        return _buildClassicDesign();
      case BillDesign.minimal:
        return _buildMinimalDesign();
      case BillDesign.modern:
        return _buildModernDesign();
      case BillDesign.invoice:
        return _buildInvoiceDesign();
    }
  }

  // ============== CLASSIC DESIGN ==============
  pw.Widget _buildClassicDesign() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisAlignment: pw.MainAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            if (shopLogo != null)
              pw.Center(child: pw.Image(pw.MemoryImage(shopLogo!), width: 36)),
            pw.SizedBox(width: 10),
            pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    shopName,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (ownerName != null && ownerName!.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      ownerName!,
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                if (phoneNumber != null && phoneNumber!.isNotEmpty)
                  pw.Center(
                    child: pw.Text(
                      'Phone: $phoneNumber',
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        pw.Text('-----------------------------------------------'),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Date: ${DateFormat('dd/MM/yyyy').format(bill.dateTime)}",
              style: const pw.TextStyle(fontSize: 7),
            ),
            pw.Center(
              child: pw.Text(
                "Invoice #${bill.id.substring(0, 8)}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 6,
                ),
              ),
            ),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (bill.customerName != null)
              pw.Text(
                "Customer: ${bill.customerName}",
                style: const pw.TextStyle(fontSize: 7),
              ),
            pw.Text(
              "Payment Status:${bill.status}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 6),
            ),
          ],
        ),
        pw.Divider(),
        _buildItemsHeader(),
        pw.Divider(),
        ..._buildItemsList(),
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        _buildTotalsSection(),
        _buildPaidStampSection(),
        pw.SizedBox(height: 4),
        pw.Divider(),
        _buildFooterSection(),
        _buildBankDetailsSection(),
      ],
    );
  }

  // ============== MINIMAL DESIGN ==============
  pw.Widget _buildMinimalDesign() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Minimal header
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                shopName,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (phoneNumber != null && phoneNumber!.isNotEmpty)
                pw.Text(phoneNumber!, style: const pw.TextStyle(fontSize: 7)),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        // Simple info line
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "#${bill.id.substring(0, 8)}",
              style: const pw.TextStyle(fontSize: 7),
            ),
            pw.Text(
              DateFormat('dd/MM/yy').format(bill.dateTime),
              style: const pw.TextStyle(fontSize: 7),
            ),
          ],
        ),
        if (bill.customerName != null)
          pw.Text(
            "${bill.customerName}",
            style: const pw.TextStyle(fontSize: 7),
          ),
        pw.SizedBox(height: 6),
        pw.Container(height: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        // Minimal items list
        ...bill.items.map((item) {
          final qty = bill.quantities[item.id] ?? 1;
          final total = item.price * qty;
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    "${item.name} x$qty",
                    style: const pw.TextStyle(fontSize: 7),
                    maxLines: 1,
                  ),
                ),
                pw.Text(
                  "Rs.${total.toStringAsFixed(0)}",
                  style: const pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 4),
        pw.Container(height: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        // Minimal totals
        if (bill.discount > 0)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Discount", style: const pw.TextStyle(fontSize: 7)),
              pw.Text(
                "-Rs.${bill.discount.toStringAsFixed(0)}",
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Total",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              "Rs.${bill.totalAfterDiscount.toStringAsFixed(0)}",
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
        if (bill.paidAmount > 0 &&
            bill.paidAmount < bill.totalAfterDiscount) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Paid", style: const pw.TextStyle(fontSize: 7)),
              pw.Text(
                "Rs.${bill.paidAmount.toStringAsFixed(0)}",
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Due",
                style: pw.TextStyle(fontSize: 7, color: PdfColors.red),
              ),
              pw.Text(
                "Rs.${bill.pendingAmount.toStringAsFixed(0)}",
                style: pw.TextStyle(fontSize: 7, color: PdfColors.red),
              ),
            ],
          ),
        ],
        _buildPaidStampSection(),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            tagline ?? "Thank you",
            style: const pw.TextStyle(fontSize: 7),
          ),
        ),
        _buildBankDetailsSection(),
      ],
    );
  }

  // ============== MODERN DESIGN (A4 Invoice) ==============
  pw.Widget _buildModernDesign() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Invoice Header Banner
        pw.Container(
          color: PdfColors.blue100,
          padding: const pw.EdgeInsets.symmetric(vertical: 6),
          child: pw.Center(
            child: pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 10),

        // Header with Logo and Shop Info
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (shopLogo != null)
              pw.Container(
                width: 80,
                height: 80,
                child: pw.Image(pw.MemoryImage(shopLogo!)),
              ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    shopName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (ownerName != null && ownerName!.isNotEmpty)
                    pw.Text(
                      'CEO: $ownerName',
                      style: const pw.TextStyle(fontSize: 11),
                    ),
                  if (shopAddress != null && shopAddress!.isNotEmpty)
                    pw.Text(
                      shopAddress!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (shopCity != null && shopCity!.isNotEmpty)
                    pw.Text(shopCity!, style: const pw.TextStyle(fontSize: 10)),
                  if (phoneNumber != null && phoneNumber!.isNotEmpty)
                    pw.Text(
                      'Phone: $phoneNumber',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),

        // Invoice Details Section
        pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To: ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        bill.customerName ?? 'Walk-in Customer',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Invoice No.',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "  #${bill.id.substring(0, 8)}",
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Date:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        ' ${DateFormat('dd/MM/yyyy').format(bill.dateTime)}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 5),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Time:',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        ' ${DateFormat('HH:mm').format(bill.dateTime)}',
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),

        // Items Table Header
        pw.Text(
          'Items',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),

        // Items Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _modernTableCell('Item', isHeader: true),
                _modernTableCell(
                  'Price',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
                _modernTableCell(
                  'Qty',
                  isHeader: true,
                  align: pw.TextAlign.center,
                ),
                _modernTableCell(
                  'Total',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
              ],
            ),
            // Item rows
            ...bill.items.map((item) {
              final qty = bill.quantities[item.id] ?? 1;
              final total = item.price * qty;
              return pw.TableRow(
                children: [
                  _modernTableCell(item.name),
                  _modernTableCell(
                    'Rs.${item.price.toStringAsFixed(0)}',
                    align: pw.TextAlign.right,
                  ),
                  _modernTableCell(qty.toString(), align: pw.TextAlign.center),
                  _modernTableCell(
                    'Rs.${total.toStringAsFixed(0)}',
                    align: pw.TextAlign.right,
                  ),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 15),

        // Totals Section
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 200,
              child: pw.Column(
                children: [
                  _modernTotalRow(
                    'Subtotal',
                    'Rs.${bill.totalAmount.toStringAsFixed(0)}',
                  ),
                  if (bill.discount > 0)
                    _modernTotalRow(
                      'Discount',
                      '-Rs.${bill.discount.toStringAsFixed(0)}',
                    ),
                  pw.Divider(),
                  _modernTotalRow(
                    'Total',
                    'Rs.${bill.totalAfterDiscount.toStringAsFixed(0)}',
                    isBold: true,
                    fontSize: 14,
                  ),
                  if (bill.paidAmount > 0)
                    _modernTotalRow(
                      'Paid',
                      'Rs.${bill.paidAmount.toStringAsFixed(0)}',
                    ),
                  if (bill.pendingAmount > 0)
                    _modernTotalRow(
                      'Balance Due',
                      'Rs.${bill.pendingAmount.toStringAsFixed(0)}',
                      isBold: true,
                      textColor: PdfColors.red,
                    ),
                ],
              ),
            ),
          ],
        ),

        // // Payment Status Badge
        // pw.SizedBox(height: 10),
        // pw.Row(
        //   mainAxisAlignment: pw.MainAxisAlignment.end,
        //   children: [
        //     pw.Container(
        //       padding: const pw.EdgeInsets.symmetric(
        //         horizontal: 12,
        //         vertical: 6,
        //       ),
        //       decoration: pw.BoxDecoration(
        //         color:
        //             bill.status == 'Paid'
        //                 ? PdfColors.green100
        //                 : PdfColors.orange100,
        //         borderRadius: pw.BorderRadius.circular(4),
        //         border: pw.Border.all(
        //           color:
        //               bill.status == 'Paid'
        //                   ? PdfColors.green700
        //                   : PdfColors.orange700,
        //         ),
        //       ),
        //       child: pw.Text(
        //         bill.status.toUpperCase(),
        //         style: pw.TextStyle(
        //           fontSize: 12,
        //           fontWeight: pw.FontWeight.bold,
        //           color:
        //               bill.status == 'Paid'
        //                   ? PdfColors.green800
        //                   : PdfColors.orange800,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),
        _buildPaidStampSection(),
        pw.SizedBox(height: 10),

        // Terms and Conditions
        if (termsAndConditions != null && termsAndConditions!.isNotEmpty) ...[
          pw.Text(
            'Terms and Conditions:',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          ...termsAndConditions!.map(
            (term) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(term, style: const pw.TextStyle(fontSize: 8)),
            ),
          ),
          pw.SizedBox(height: 2),
        ],

        pw.Divider(),
        pw.SizedBox(height: 2),

        // Social Media Handles
        _buildSocialMediaSection(),

        // Footer
        pw.SizedBox(height: 2),
        // pw.Center(
        //   child: pw.Text(
        //     tagline ?? 'Thank you for your business!',
        //     style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic),
        //   ),
        // ),

        // Bank Details
        pw.Align(
          alignment: pw.Alignment.topLeft,
          child: _buildBankDetailsSection(),
        ),
      ],
    );
  }

  // ============== INVOICE DESIGN (Trader-style with sidebar) ==============
  pw.Widget _buildInvoiceDesign() {
    final accentColor = PdfColors.orange;
    final accentLight = PdfColors.orange50;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ── Left Sidebar ──
        pw.Container(
          width: 160,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: accentColor,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Shop Name
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "Invoice",
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),

              pw.SizedBox(height: 20),
              // Shop Logo
              if (shopLogo != null) ...[
                pw.Container(
                  width: 70,
                  height: 70,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Image(pw.MemoryImage(shopLogo!)),
                ),
                pw.SizedBox(height: 10),
              ],
              // Shop Name
              pw.Text(
                shopName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 16),

              // Address
              if (shopAddress != null && shopAddress!.isNotEmpty)
                pw.Text(
                  shopAddress!,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              if (shopCity != null && shopCity!.isNotEmpty)
                pw.Text(
                  shopCity!,
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              pw.SizedBox(height: 8),
              // ! owner name is optional, only show if provided
              if (ownerName != null && ownerName!.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  ownerName!,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
              ],
              //! Phone with icon
              if (phoneNumber != null && phoneNumber!.isNotEmpty)
                _invoiceSidebarContactRow(phoneIcon, phoneNumber!),
              pw.SizedBox(height: 4),
              // Email with icon
              if (email != null && email!.isNotEmpty)
                _invoiceSidebarContactRow(emailIcon, email!),
              pw.SizedBox(height: 4),
              // Social media handles with icons
              if (socialMediaHandles != null) ...[
                if (socialMediaHandles!.containsKey('facebook') &&
                    socialMediaHandles!['facebook']!.isNotEmpty)
                  _invoiceSidebarContactRow(
                    facebookIcon,
                    socialMediaHandles!['facebook']!,
                  ),
                if (socialMediaHandles!.containsKey('instagram') &&
                    socialMediaHandles!['instagram']!.isNotEmpty)
                  _invoiceSidebarContactRow(
                    instagramIcon,
                    socialMediaHandles!['instagram']!,
                  ),
                if (socialMediaHandles!.containsKey('whatsapp') &&
                    socialMediaHandles!['whatsapp']!.isNotEmpty)
                  _invoiceSidebarContactRow(
                    whatsappIcon,
                    socialMediaHandles!['whatsapp']!,
                  ),
                if (socialMediaHandles!.containsKey('twitter') &&
                    socialMediaHandles!['twitter']!.isNotEmpty)
                  _invoiceSidebarContactRow(
                    twitterIcon,
                    socialMediaHandles!['twitter']!,
                  ),
              ],
              pw.SizedBox(height: 8),
              pw.Spacer(),
              //! Bank details
              pw.Align(
                alignment: pw.Alignment.topLeft,
                child: _buildBankDetailsSection(isTopDivider: false),
              ),
              pw.SizedBox(height: 15),

              // Terms
              if (termsAndConditions != null &&
                  termsAndConditions!.isNotEmpty) ...[
                pw.Container(height: 0.5, color: PdfColors.white),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Terms and Conditions:',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                ...termsAndConditions!.map(
                  (term) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 1),
                    child: pw.Text(
                      term,
                      style: const pw.TextStyle(fontSize: 7),
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(height: 0.5, color: PdfColors.white),
              ],
              // Tagline
              if (tagline != null && tagline!.isNotEmpty) ...[
                pw.SizedBox(height: 20),

                pw.Text(
                  tagline!,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 15),

        // ── Right Content ──
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Date & Invoice No row
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'DATE: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy').format(bill.dateTime),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Text(
                        'INVOICE NO: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '#${bill.id.substring(0, 8)}',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),

              // Bill To / Phone / Payment
              _invoiceInfoRow(
                'Bill To:',
                bill.customerName ?? 'Walk-in Customer',
              ),
              _invoiceInfoRow('Phone:', customerPhone ?? ''),
              _invoiceInfoRow('Payment:', bill.paymentMethod ?? 'Cash'),
              pw.SizedBox(height: 12),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.5),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      _invoiceTableCell('Description', isHeader: true),
                      _invoiceTableCell(
                        'Qty',
                        isHeader: true,
                        align: pw.TextAlign.center,
                      ),
                      _invoiceTableCell(
                        'Unit Price',
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                      _invoiceTableCell(
                        'Total',
                        isHeader: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                  // Item rows
                  ...bill.items.map((item) {
                    final qty = bill.quantities[item.id] ?? 1;
                    final total = item.price * qty;
                    return pw.TableRow(
                      children: [
                        _invoiceTableCell(item.name),
                        _invoiceTableCell(
                          qty.toString(),
                          align: pw.TextAlign.center,
                        ),
                        _invoiceTableCell(
                          'Rs.${item.price.toStringAsFixed(0)}',
                          align: pw.TextAlign.right,
                        ),
                        _invoiceTableCell(
                          'Rs.${total.toStringAsFixed(0)}',
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 10),

              // Totals section with paid stamp side by side
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Paid stamp (left side)
                  pw.Expanded(
                    child: pw.Container(
                      alignment: pw.Alignment.center,
                      child: _buildPaidStampSection(),
                    ),
                  ),
                  // Totals table (right side)
                  pw.Container(
                    width: 220,
                    child: pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey400),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1.2),
                        1: const pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        _invoiceTotalRow(
                          'Sub Total',
                          'Rs.${bill.totalAfterDiscount.toStringAsFixed(0)}',
                        ),
                        if (bill.discount > 0)
                          _invoiceTotalRow(
                            'Discount',
                            'Rs.${bill.discount.toStringAsFixed(0)}',
                          ),
                        _invoiceTotalRow(
                          'Advance',
                          bill.paidAmount > 0
                              ? 'Rs.${bill.paidAmount.toStringAsFixed(0)}'
                              : '',
                        ),
                        _invoiceTotalRow(
                          'Balance',
                          bill.pendingAmount > 0
                              ? 'Rs.${bill.pendingAmount.toStringAsFixed(0)}'
                              : 'Rs.0',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Signature line
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 150,
                        height: 0.5,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Signature',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Invoice design helper: Info row (label + value with underline)
  pw.Widget _invoiceInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 65,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 2),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
                ),
              ),
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
            ),
          ),
        ],
      ),
    );
  }

  // Invoice design helper: Sidebar contact row with icon
  pw.Widget _invoiceSidebarContactRow(Uint8List? icon, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          if (icon != null) ...[
            pw.Image(pw.MemoryImage(icon), width: 12, height: 12),
            pw.SizedBox(width: 6),
          ],
          pw.Expanded(
            child: pw.Text(
              text,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Invoice design helper: Table cell
  pw.Widget _invoiceTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  // Invoice design helper: Total row for the summary table
  pw.TableRow _invoiceTotalRow(
    String label,
    String value, {
    bool isBold = false,
  }) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  // Modern design helper: Table cell
  pw.Widget _modernTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  // Modern design helper: Total row
  pw.Widget _modernTotalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============== SHARED COMPONENTS ==============
  pw.Widget _buildItemsHeader() {
    return pw.Row(
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            "Item",
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
          ),
        ),
        pw.SizedBox(
          width: 30,
          child: pw.Text(
            "Price",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            textAlign: pw.TextAlign.right,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.SizedBox(
          width: 30,
          child: pw.Text(
            "Qty",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(width: 5),
        pw.SizedBox(
          width: 35,
          child: pw.Text(
            "Total",
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<pw.Widget> _buildItemsList() {
    return bill.items.map((item) {
      final qty = bill.quantities[item.id] ?? 1;
      final total = item.price * qty;
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 1,
              child: pw.Text(
                item.name,
                style: const pw.TextStyle(fontSize: 7),
                maxLines: 2,
                overflow: pw.TextOverflow.clip,
              ),
            ),
            pw.SizedBox(
              width: 30,
              child: pw.Text(
                "Rs.${item.price.toStringAsFixed(0)}",
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.SizedBox(width: 5),
            pw.SizedBox(
              width: 30,
              child: pw.Text(
                qty.toStringAsFixed(0),
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.SizedBox(width: 5),
            pw.SizedBox(
              width: 30,
              child: pw.Text(
                "Rs.${total.toStringAsFixed(0)}",
                style: const pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  pw.Widget _buildTotalsSection() {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Subtotal:", style: const pw.TextStyle(fontSize: 8)),
            pw.Text(
              "Rs.${bill.totalAmount.toStringAsFixed(2)}",
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        if (bill.discount > 0) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Discount:", style: const pw.TextStyle(fontSize: 7)),
              pw.Text(
                "- Rs.${bill.discount.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
        pw.Divider(borderStyle: pw.BorderStyle.dashed),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text("Total:", style: const pw.TextStyle(fontSize: 7)),
            pw.Text(
              "Rs.${bill.totalAfterDiscount.toStringAsFixed(2)}",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            ),
          ],
        ),
        if (bill.paidAmount > 0) ...[
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Pay  ${bill.paymentMethod != null ? '${bill.paymentMethod}' : ''}",
                style: const pw.TextStyle(fontSize: 7),
              ),
              pw.Text(
                "Rs.${bill.paidAmount.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
        if (bill.pendingAmount > 0) ...[
          pw.Divider(borderStyle: pw.BorderStyle.dashed),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Amount Due:",
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                ),
                pw.Text(
                  "Rs.${bill.pendingAmount.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildFooterSection() {
    if (tagline != null && tagline!.isNotEmpty) {
      return pw.Center(
        child: pw.Text(
          tagline!,
          style: const pw.TextStyle(fontSize: 7),
          textAlign: pw.TextAlign.center,
        ),
      );
    }
    return pw.Center(
      child: pw.Text(
        "Thank you for your business!",
        style: const pw.TextStyle(fontSize: 7),
      ),
    );
  }

  pw.Widget _buildBankDetailsSection({bool? isTopDivider = true}) {
    if (bankName == null && accountNumber == null && bankQrCode == null) {
      return pw.SizedBox();
    }

    final isModern =
        billDesign == BillDesign.modern || billDesign == BillDesign.invoice;
    final titleFontSize = isModern ? 14.0 : 10.0;
    final detailFontSize = isModern ? 11.0 : 9.0;
    final smallFontSize = isModern ? 9.0 : 7.0;
    final qrSize = isModern ? 100.0 : 70.0;

    return pw.Column(
      mainAxisAlignment:
          isModern ? pw.MainAxisAlignment.start : pw.MainAxisAlignment.center,
      crossAxisAlignment:
          isModern ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.center,
      children: [
        isTopDivider ?? true ? pw.Divider() : pw.SizedBox(),
        pw.SizedBox(height: isModern ? 10 : 4),
        // pw.Center(
        //   child: pw.Text(
        //     "Bank Details",
        //     style: pw.TextStyle(
        //       fontSize: titleFontSize,
        //       fontWeight: pw.FontWeight.bold,
        //     ),
        //   ),
        // ),
        pw.SizedBox(height: isModern ? 8 : 4),

        if (isModern)
          // Modern layout: QR on left, details on right
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              if (bankQrCode != null) ...[
                pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Image(
                        pw.MemoryImage(bankQrCode!),
                        width: qrSize,
                        height: qrSize,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    isModern
                        ? pw.SizedBox.shrink()
                        : pw.Text(
                          "Scan to Pay",
                          style: pw.TextStyle(
                            fontSize: smallFontSize,
                            color: PdfColors.grey700,
                          ),
                        ),
                  ],
                ),
                pw.SizedBox(width: 20),
              ],
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (bankName != null && bankName!.isNotEmpty)
                    pw.Row(
                      children: [
                        pw.Text(
                          "Bank: ",
                          style: pw.TextStyle(
                            fontSize: detailFontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          bankName!,
                          style: pw.TextStyle(fontSize: detailFontSize),
                        ),
                      ],
                    ),
                  pw.SizedBox(height: 4),
                  if (accountNumber != null && accountNumber!.isNotEmpty)
                    pw.Row(
                      children: [
                        pw.Text(
                          "A/C No: ",
                          style: pw.TextStyle(
                            fontSize: detailFontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          accountNumber!,
                          style: pw.TextStyle(fontSize: detailFontSize),
                        ),
                      ],
                    ),
                  pw.SizedBox(height: 4),
                  if (ifscCode != null && ifscCode!.isNotEmpty)
                    pw.Row(
                      children: [
                        pw.Text(
                          "IFSC: ",
                          style: pw.TextStyle(
                            fontSize: detailFontSize,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          ifscCode!,
                          style: pw.TextStyle(fontSize: detailFontSize),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          )
        else
          // Classic/Minimal layout: Stacked vertically
          pw.Column(
            children: [
              if (bankName != null && bankName!.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    "Bank: $bankName",
                    style: pw.TextStyle(
                      fontSize: detailFontSize,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              if (accountNumber != null && accountNumber!.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    "A/C: $accountNumber",
                    style: pw.TextStyle(fontSize: detailFontSize),
                  ),
                ),
              if (ifscCode != null && ifscCode!.isNotEmpty)
                pw.Center(
                  child: pw.Text(
                    "IFSC: $ifscCode",
                    style: pw.TextStyle(fontSize: smallFontSize),
                  ),
                ),
              if (bankQrCode != null) ...[
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    "Scan to pay",
                    style: pw.TextStyle(fontSize: smallFontSize),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(bankQrCode!),
                    width: qrSize,
                    height: qrSize,
                  ),
                ),
              ],
            ],
          ),
        pw.SizedBox(height: isModern ? 10 : 4),
      ],
    );
  }

  pw.Widget _buildPaidStampSection() {
    // Only show stamp if enabled and bill is paid
    if (!showPaidStamp || bill.status != 'Paid') {
      return pw.SizedBox();
    }

    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.green800, width: 2),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                paidStampText.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                  letterSpacing: 2,
                ),
              ),
              if (paidStampSignature.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  paidStampSignature,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.green700,
                  ),
                ),
              ],
              if (showDateOnStamp) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: pw.TextStyle(fontSize: 7, color: PdfColors.green600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the social media handles section with icons (for modern design)
  pw.Widget _buildSocialMediaSection() {
    if (socialMediaHandles == null || socialMediaHandles!.isEmpty) {
      return pw.SizedBox();
    }

    final List<pw.Widget> socialItems = [];

    // Facebook
    if (socialMediaHandles!.containsKey('facebook') &&
        socialMediaHandles!['facebook']!.isNotEmpty) {
      socialItems.add(
        _buildSocialMediaItem(
          icon: facebookIcon,
          label: 'Facebook',
          handle: socialMediaHandles!['facebook']!,
        ),
      );
    }

    // Instagram
    if (socialMediaHandles!.containsKey('instagram') &&
        socialMediaHandles!['instagram']!.isNotEmpty) {
      socialItems.add(
        _buildSocialMediaItem(
          icon: instagramIcon,
          label: 'Instagram',
          handle: socialMediaHandles!['instagram']!,
        ),
      );
    }

    // Twitter/X
    if (socialMediaHandles!.containsKey('twitter') &&
        socialMediaHandles!['twitter']!.isNotEmpty) {
      socialItems.add(
        _buildSocialMediaItem(
          icon: twitterIcon,
          label: 'X',
          handle: socialMediaHandles!['twitter']!,
        ),
      );
    }

    // WhatsApp
    if (socialMediaHandles!.containsKey('whatsapp') &&
        socialMediaHandles!['whatsapp']!.isNotEmpty) {
      socialItems.add(
        _buildSocialMediaItem(
          icon: whatsappIcon,
          label: 'WhatsApp',
          handle: socialMediaHandles!['whatsapp']!,
        ),
      );
    }

    // YouTube
    if (socialMediaHandles!.containsKey('youtube') &&
        socialMediaHandles!['youtube']!.isNotEmpty) {
      socialItems.add(
        _buildSocialMediaItem(
          icon: youtubeIcon,
          label: 'YouTube',
          handle: socialMediaHandles!['youtube']!,
        ),
      );
    }

    if (socialItems.isEmpty) {
      return pw.SizedBox();
    }

    // return pw.Wrap(
    //   alignment: pw.WrapAlignment.center,
    //   spacing: 15,
    //   runSpacing: 8,
    //   children: socialItems,
    // );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: socialItems,
    );
  }

  /// Builds a single social media item with icon and handle
  pw.Widget _buildSocialMediaItem({
    Uint8List? icon,
    required String label,
    required String handle,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (icon != null) ...[
          pw.Image(pw.MemoryImage(icon), width: 14, height: 14),
          pw.SizedBox(width: 4),
        ],
        pw.Text(
          handle,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }
}
