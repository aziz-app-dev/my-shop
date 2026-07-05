import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../models/shopping_list_model.dart';

class ShoppingListPDFGenerator {
  final ShoppingList shoppingList;
  final List<ShoppingListItem> items;
  final String shopName;
  final String? ownerName;

  ShoppingListPDFGenerator({
    required this.shoppingList,
    required this.items,
    required this.shopName,
    this.ownerName,
  });

  pw.Document generatePDF() {
    final pdf = pw.Document();

    // Filter out shopped items - only show pending items
    final pendingItems = items.where((item) => !item.isShopped).toList();

    // Decide if we need two columns based on item count
    final useDoubleColumn = pendingItems.length > 15;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build:
            (pw.Context context) =>
                _buildPDFContent(pendingItems, useDoubleColumn),
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFContent(
    List<ShoppingListItem> pendingItems,
    bool useDoubleColumn,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        pw.SizedBox(height: 20),

        // Main content
        if (useDoubleColumn)
          _buildDoubleColumnLayout(pendingItems)
        else
          _buildSingleColumnLayout(pendingItems),
      ],
    );
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Shop Name
                pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                // Owner Name
                if (ownerName != null && ownerName!.isNotEmpty)
                  pw.Text(
                    ownerName!,
                    style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
                  )
                else
                  pw.Text(
                    'Shopping List',
                    style: pw.TextStyle(fontSize: 16, color: PdfColors.grey700),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  shoppingList.name,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2),
      ],
    );
  }

  pw.Widget _buildSingleColumnLayout(List<ShoppingListItem> items) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          _buildTableHeader(),
          pw.SizedBox(height: 5),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildTableRow(index + 1, item);
          }),
        ],
      ),
    );
  }

  pw.Widget _buildDoubleColumnLayout(List<ShoppingListItem> items) {
    // Split items into two columns
    final midPoint = (items.length / 2).ceil();
    final leftItems = items.sublist(0, midPoint);
    final rightItems = items.sublist(midPoint);

    return pw.Expanded(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left Column
          pw.Expanded(
            child: pw.Column(
              children: [
                _buildTableHeader(),
                pw.SizedBox(height: 5),
                ...leftItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildTableRow(index + 1, item);
                }),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          // Right Column
          pw.Expanded(
            child: pw.Column(
              children: [
                _buildTableHeader(),
                pw.SizedBox(height: 5),
                ...rightItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildTableRow(midPoint + index + 1, item);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey300,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 30,
            child: pw.Text(
              'No',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              'Item',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.SizedBox(
            width: 40,
            child: pw.Text(
              'Qty',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableRow(int number, ShoppingListItem item) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 30,
            child: pw.Text(
              number.toString(),
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.productName,
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if (item.brand != null)
                  pw.Text(
                    item.brand!,
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey600,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          pw.SizedBox(
            width: 40,
            child: pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                item.quantityNeeded.toString(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
