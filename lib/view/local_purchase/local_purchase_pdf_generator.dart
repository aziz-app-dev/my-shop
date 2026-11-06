import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../models/local_purchase_model.dart';

class LocalPurchasePDFGenerator {
  final LocalPurchaseAgreement agreement;
  final String shopName;
  final String? ownerName;
  final String? shopAddress;
  final String? shopPhone;
  final Uint8List? shopLogo;

  LocalPurchasePDFGenerator({
    required this.agreement,
    required this.shopName,
    this.ownerName,
    this.shopAddress,
    this.shopPhone,
    this.shopLogo,
  });

  pw.Document generatePDF() {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        build: (pw.Context context) => _buildContent(),
      ),
    );

    return pdf;
  }

  pw.Widget _buildContent() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        pw.SizedBox(height: 20),
        _buildAgreementInfo(),
        pw.SizedBox(height: 16),
        _buildSellerDetails(),
        pw.SizedBox(height: 16),
        _buildItemsTable(),
        pw.SizedBox(height: 16),
        _buildPaymentSection(),
        pw.SizedBox(height: 16),
        _buildTermsSection(),
        pw.SizedBox(height: 24),
        _buildSignatureSection(),
        pw.SizedBox(height: 16),
        _buildFooter(),
      ],
    );
  }

  pw.Widget _buildHeader() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (shopLogo != null) ...[
          pw.Container(
            width: 60,
            height: 60,
            child: pw.Image(pw.MemoryImage(shopLogo!)),
          ),
          pw.SizedBox(width: 16),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                shopName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (ownerName != null && ownerName!.isNotEmpty)
                pw.Text(
                  'Owner: $ownerName',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              if (shopAddress != null && shopAddress!.isNotEmpty)
                pw.Text(
                  shopAddress!,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              if (shopPhone != null && shopPhone!.isNotEmpty)
                pw.Text(
                  'Phone: $shopPhone',
                  style: const pw.TextStyle(fontSize: 9),
                ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            border: pw.Border.all(color: PdfColors.blue800),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'LOCAL PURCHASE\nAGREEMENT',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildAgreementInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _infoRow('Agreement No:', '#${agreement.id.substring(0, 8)}'),
              pw.SizedBox(height: 4),
              _infoRow(
                'Date:',
                DateFormat('dd MMM yyyy').format(agreement.dateTime),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _infoRow('Payment Type:', agreement.paymentType),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 6),
        pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  pw.Widget _buildSellerDetails() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Seller Details',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Divider(color: PdfColors.grey300),
          _sellerInfoRow('Name:', agreement.sellerName),
          if (agreement.sellerPhone != null &&
              agreement.sellerPhone!.isNotEmpty)
            _sellerInfoRow('Phone:', agreement.sellerPhone!),
          if (agreement.sellerIdCard != null &&
              agreement.sellerIdCard!.isNotEmpty)
            _sellerInfoRow('ID Card No:', agreement.sellerIdCard!),
          if (agreement.sellerAddress != null &&
              agreement.sellerAddress!.isNotEmpty)
            _sellerInfoRow('Address:', agreement.sellerAddress!),
        ],
      ),
    );
  }

  pw.Widget _sellerInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Purchased Items',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(3.5),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Item Name', isHeader: true),
                _tableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                _tableCell(
                  'Unit Price',
                  isHeader: true,
                  align: pw.TextAlign.right,
                ),
                _tableCell('Total', isHeader: true, align: pw.TextAlign.right),
              ],
            ),
            // Rows
            ...agreement.items.map((item) {
              return pw.TableRow(
                children: [
                  _tableCell(item.name),
                  _tableCell(
                    item.quantity.toString(),
                    align: pw.TextAlign.center,
                  ),
                  _tableCell(
                    'Rs.${item.unitPrice.toStringAsFixed(0)}',
                    align: pw.TextAlign.right,
                  ),
                  _tableCell(
                    'Rs.${item.totalPrice.toStringAsFixed(0)}',
                    align: pw.TextAlign.right,
                  ),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 200,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Grand Total',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Rs.${agreement.totalAmount.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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

  pw.Widget _buildPaymentSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Payment Details',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                _infoRow('Payment Type:', agreement.paymentType),
                _infoRow(
                  'Total Amount:',
                  'Rs.${agreement.totalAmount.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTermsSection() {
    if (agreement.termsAndConditions.isEmpty) {
      return pw.SizedBox();
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Terms & Conditions',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 6),
        ...agreement.termsAndConditions.map(
          (term) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(term, style: const pw.TextStyle(fontSize: 8)),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignatureSection() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Seller signature
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 180,
                height: 0.5,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                agreement.sellerSignature?.isNotEmpty == true
                    ? agreement.sellerSignature!
                    : 'Seller Signature',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: agreement.sellerSignature?.isNotEmpty == true
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
              pw.Text(
                'Seller',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        // Owner signature
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 180,
                height: 0.5,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                agreement.ownerSignature?.isNotEmpty == true
                    ? agreement.ownerSignature!
                    : (ownerName?.isNotEmpty == true
                        ? ownerName!
                        : 'Owner Signature'),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: agreement.ownerSignature?.isNotEmpty == true
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
              pw.Text(
                'Shop Owner',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'This agreement is electronically generated and serves as a legal record of the transaction.',
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 7,
          color: PdfColors.grey500,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }
}
