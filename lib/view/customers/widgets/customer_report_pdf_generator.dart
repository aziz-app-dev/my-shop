import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/bills_model.dart';
import '../../../models/coustomer_model.dart';

class CustomerReportPDFGenerator {
  final Customer customer;
  final List<Bill> bills;
  final String shopName;
  final Uint8List? shopLogo;
  final String? ownerName;
  final String? phoneNumber;
  final String? shopAddress;
  final double totalSpending;
  final double totalPending;

  CustomerReportPDFGenerator({
    required this.customer,
    required this.bills,
    required this.shopName,
    this.shopLogo,
    this.ownerName,
    this.phoneNumber,
    this.shopAddress,
    this.totalSpending = 0.0,
    this.totalPending = 0.0,
  });

  pw.Document generatePDF() {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) => [
          _buildCustomerInfo(),
          pw.SizedBox(height: 15),
          _buildSummarySection(),
          pw.SizedBox(height: 15),
          _buildPurchaseHistory(),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (shopLogo != null)
                pw.Container(
                  width: 60,
                  height: 60,
                  child: pw.Image(pw.MemoryImage(shopLogo!)),
                ),
              pw.SizedBox(width: 10),
              pw.Column(
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
                      ownerName!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (phoneNumber != null && phoneNumber!.isNotEmpty)
                    pw.Text(
                      'Phone: $phoneNumber',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  if (shopAddress != null && shopAddress!.isNotEmpty)
                    pw.Text(
                      shopAddress!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'CUSTOMER REPORT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Customer Report - ${customer.name}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCustomerInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Customer Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow('Name', customer.name),
                    pw.SizedBox(height: 5),
                    _infoRow('Customer ID', customer.id.substring(0, 8)),
                    pw.SizedBox(height: 5),
                    _infoRow(
                      'Phone',
                      customer.phoneNumber.isEmpty ? 'N/A' : customer.phoneNumber,
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _infoRow(
                      'Address',
                      customer.address.isEmpty ? 'N/A' : customer.address,
                    ),
                    pw.SizedBox(height: 5),
                    _infoRow('Total Visits', customer.visitCount.toString()),
                    pw.SizedBox(height: 5),
                    _infoRow('Total Bills', bills.length.toString()),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSummarySection() {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _summaryCard(
            'Total Spending',
            'Rs.${totalSpending.toStringAsFixed(2)}',
            PdfColors.green700,
            PdfColors.green50,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryCard(
            'Pending Amount',
            'Rs.${totalPending.toStringAsFixed(2)}',
            totalPending > 0 ? PdfColors.red700 : PdfColors.green700,
            totalPending > 0 ? PdfColors.red50 : PdfColors.green50,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _summaryCard(
            'Total Bills',
            bills.length.toString(),
            PdfColors.blue700,
            PdfColors.blue50,
          ),
        ),
      ],
    );
  }

  pw.Widget _summaryCard(
    String title,
    String value,
    PdfColor textColor,
    PdfColor bgColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPurchaseHistory() {
    if (bills.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Center(
          child: pw.Text(
            'No purchase history available',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Purchase History',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...bills.map((bill) => _buildBillCard(bill)),
      ],
    );
  }

  pw.Widget _buildBillCard(Bill bill) {
    final finalAmount = bill.totalAmount - bill.discount;
    final pendingAmount = finalAmount - bill.paidAmount;
    final isPaid = pendingAmount <= 0.01;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: isPaid ? PdfColors.green300 : PdfColors.orange300,
        ),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Bill Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Text(
                    'Bill #${bill.id.substring(0, 8)}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: isPaid ? PdfColors.green100 : PdfColors.orange100,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      isPaid ? 'PAID' : 'PENDING',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: isPaid ? PdfColors.green800 : PdfColors.orange800,
                      ),
                    ),
                  ),
                ],
              ),
              pw.Text(
                DateFormat('dd MMM yyyy, HH:mm').format(bill.dateTime),
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ),
          pw.SizedBox(height: 8),

          // Items Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableCell('Item', isHeader: true),
                  _tableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                  _tableCell('Price', isHeader: true, align: pw.TextAlign.right),
                  _tableCell('Total', isHeader: true, align: pw.TextAlign.right),
                ],
              ),
              // Item rows
              ...bill.items.map((item) {
                final qty = bill.quantities[item.id] ?? 1;
                final total = item.price * qty;
                return pw.TableRow(
                  children: [
                    _tableCell(item.name),
                    _tableCell(qty.toString(), align: pw.TextAlign.center),
                    _tableCell(
                      'Rs.${item.price.toStringAsFixed(2)}',
                      align: pw.TextAlign.right,
                    ),
                    _tableCell(
                      'Rs.${total.toStringAsFixed(2)}',
                      align: pw.TextAlign.right,
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 8),

          // Bill Summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 150,
                child: pw.Column(
                  children: [
                    _summaryRow('Subtotal', 'Rs.${bill.totalAmount.toStringAsFixed(2)}'),
                    if (bill.discount > 0)
                      _summaryRow(
                        'Discount',
                        '-Rs.${bill.discount.toStringAsFixed(2)}',
                        textColor: PdfColors.green700,
                      ),
                    pw.Divider(color: PdfColors.grey400),
                    _summaryRow(
                      'Total',
                      'Rs.${finalAmount.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                    if (bill.paidAmount > 0)
                      _summaryRow(
                        'Paid',
                        'Rs.${bill.paidAmount.toStringAsFixed(2)}',
                        textColor: PdfColors.green700,
                      ),
                    if (pendingAmount > 0)
                      _summaryRow(
                        'Due',
                        'Rs.${pendingAmount.toStringAsFixed(2)}',
                        textColor: PdfColors.red700,
                        isBold: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
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

  pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
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
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
