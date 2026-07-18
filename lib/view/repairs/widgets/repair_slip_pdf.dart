import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/repair_model.dart';

/// Builds a printable / shareable A4 "Repair Slip" PDF for a single [Repair] —
/// the repair-shop equivalent of the invoice PDF. Self-contained: it takes the
/// shop header details as plain values so it has no dependency on Riverpod/Hive.
class RepairSlipPdfGenerator {
  final Repair repair;
  final String shopName;
  final String? ownerName;
  final String? shopPhone;
  final String? shopAddress;
  final String? tagline;
  final Uint8List? shopLogo;

  RepairSlipPdfGenerator({
    required this.repair,
    required this.shopName,
    this.ownerName,
    this.shopPhone,
    this.shopAddress,
    this.tagline,
    this.shopLogo,
  });

  static final NumberFormat _money = NumberFormat('#,##0', 'en');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static const PdfColor _accent = PdfColor.fromInt(0xFFff6701);

  String _rs(double v) => 'Rs. ${_money.format(v)}';

  String get _shortId =>
      repair.id.length >= 8 ? repair.id.substring(0, 8) : repair.id;

  Future<Uint8List> build() async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(),
              pw.SizedBox(height: 10),
              _titleBar(),
              pw.SizedBox(height: 14),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: _infoBlock('CLIENT', [
                      _kv('Name', repair.clientName),
                      if (repair.clientPhone.isNotEmpty)
                        _kv('Phone', repair.clientPhone),
                    ]),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: _infoBlock('DEVICE', [
                      if (repair.deviceType.isNotEmpty)
                        _kv('Type', repair.deviceType),
                      if (repair.brand.isNotEmpty) _kv('Brand', repair.brand),
                      if (repair.model.isNotEmpty) _kv('Model', repair.model),
                      if (repair.serialNumber.isNotEmpty)
                        _kv('Serial', repair.serialNumber),
                    ]),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              if (repair.problem.isNotEmpty)
                _paragraph('Reported Problem', repair.problem),
              if (repair.accessories.isNotEmpty)
                _paragraph('Accessories Received', repair.accessories),
              if (repair.items.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                _sectionLabel('Parts / Services'),
                pw.SizedBox(height: 6),
                _itemsTable(),
              ],
              pw.SizedBox(height: 14),
              _costSummary(),
              pw.SizedBox(height: 16),
              _datesRow(),
              pw.Spacer(),
              _footer(),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ---- Sections ----------------------------------------------------------

  pw.Widget _header() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (shopLogo != null) ...[
          pw.Container(
            width: 54,
            height: 54,
            child: pw.Image(pw.MemoryImage(shopLogo!), fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                shopName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                ),
              ),
              if (tagline != null && tagline!.isNotEmpty)
                pw.Text(
                  tagline!,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              pw.SizedBox(height: 2),
              if (shopAddress != null && shopAddress!.isNotEmpty)
                pw.Text(shopAddress!,
                    style: const pw.TextStyle(fontSize: 9)),
              if (shopPhone != null && shopPhone!.isNotEmpty)
                pw.Text('Phone: ${shopPhone!}',
                    style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _titleBar() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const pw.BoxDecoration(color: _accent),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'REPAIR SLIP',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'Slip #$_shortId',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoBlock(String title, List<pw.Widget> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
            ),
          ),
          pw.SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 52,
            child: pw.Text('$k:',
                style: const pw.TextStyle(
                    fontSize: 9, color: PdfColors.grey700)),
          ),
          pw.Expanded(
            child: pw.Text(
              v,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _sectionLabel(String text) {
    return pw.Text(
      text,
      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    );
  }

  pw.Widget _paragraph(String title, String body) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel(title),
          pw.SizedBox(height: 3),
          pw.Text(body, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _itemsTable() {
    pw.Widget cell(String text,
        {pw.TextAlign align = pw.TextAlign.left, bool header = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: header ? PdfColors.white : PdfColors.black,
          ),
        ),
      );
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _accent),
        children: [
          cell('Item', header: true),
          cell('Qty', align: pw.TextAlign.center, header: true),
          cell('Price', align: pw.TextAlign.right, header: true),
          cell('Total', align: pw.TextAlign.right, header: true),
        ],
      ),
      for (final it in repair.items)
        pw.TableRow(
          children: [
            cell(it.name),
            cell('${it.quantity}', align: pw.TextAlign.center),
            cell(_rs(it.price), align: pw.TextAlign.right),
            cell(_rs(it.total), align: pw.TextAlign.right),
          ],
        ),
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(5),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: rows,
    );
  }

  pw.Widget _costSummary() {
    pw.Widget line(String label, String value, {bool emphasize = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: emphasize ? 11 : 10,
                fontWeight: emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: emphasize ? _accent : PdfColors.grey800,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: emphasize ? 11 : 10,
                fontWeight: pw.FontWeight.bold,
                color: emphasize ? _accent : PdfColors.black,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 230,
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              line('Estimated Cost', _rs(repair.estimatedCost)),
              line('Advance Paid', _rs(repair.advancePaid)),
              pw.Divider(color: PdfColors.grey400, height: 8),
              line('Balance Due', _rs(repair.balanceDue), emphasize: true),
            ],
          ),
        ),
      ),
    );
  }

  pw.Widget _datesRow() {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _kv('Received', _dateTime.format(repair.receivedDate)),
        ),
        pw.Expanded(
          child: _kv(
            'Expected',
            repair.expectedDate != null
                ? _date.format(repair.expectedDate!)
                : '—',
          ),
        ),
        pw.Expanded(
          child: _kv('Status', repair.isCompleted ? 'Completed' : 'In Repair'),
        ),
      ],
    );
  }

  pw.Widget _footer() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.Text(
          'Terms: Items not collected within 30 days may be sold to recover '
          'costs. Please bring this slip when collecting your device.',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 24),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _signatureLine('Client Signature'),
            _signatureLine('Authorized Signature'),
          ],
        ),
      ],
    );
  }

  pw.Widget _signatureLine(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(width: 150, height: 0.7, color: PdfColors.grey600),
        pw.SizedBox(height: 3),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }
}
