import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../models/expense_model.dart';

class ExpensePDFGenerator {
  final List<Expense> expenses;
  final DateTime selectedMonth;
  final String shopName;
  final String? ownerName;
  final double totalAmount;
  final Map<String, double> expensesByCategory;

  ExpensePDFGenerator({
    required this.expenses,
    required this.selectedMonth,
    required this.shopName,
    this.ownerName,
    required this.totalAmount,
    required this.expensesByCategory,
  });

  pw.Document generatePDF() {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildSummarySection(),
          pw.SizedBox(height: 20),
          _buildCategoryBreakdown(),
          pw.SizedBox(height: 20),
          _buildExpenseTable(),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildHeader() {
    final monthName = DateFormat('MMMM yyyy').format(selectedMonth);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  shopName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (ownerName != null && ownerName!.isNotEmpty)
                  pw.Text(
                    ownerName!,
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Expense Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  monthName,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Divider(thickness: 2, color: PdfColors.blue800),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      ),
    );
  }

  pw.Widget _buildSummarySection() {
    final avgExpense = expenses.isNotEmpty ? totalAmount / expenses.length : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Expenses', 'Rs.${totalAmount.toStringAsFixed(2)}', PdfColors.blue800),
          _buildSummaryItem('Transactions', expenses.length.toString(), PdfColors.orange800),
          _buildSummaryItem('Average', 'Rs.${avgExpense.toStringAsFixed(2)}', PdfColors.green800),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCategoryBreakdown() {
    if (expensesByCategory.isEmpty) {
      return pw.SizedBox();
    }

    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Category Breakdown',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(4),
                    topRight: pw.Radius.circular(4),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'Category',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    pw.SizedBox(
                      width: 80,
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.SizedBox(
                      width: 60,
                      child: pw.Text(
                        '%',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              // Rows
              ...sortedCategories.map((entry) {
                final percentage = (entry.value / totalAmount) * 100;
                return pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(entry.key, style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.SizedBox(
                        width: 80,
                        child: pw.Text(
                          'Rs.${entry.value.toStringAsFixed(2)}',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                      pw.SizedBox(
                        width: 60,
                        child: pw.Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildExpenseTable() {
    if (expenses.isEmpty) {
      return pw.Center(
        child: pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Text(
            'No expenses recorded for this month',
            style: const pw.TextStyle(color: PdfColors.grey600),
          ),
        ),
      );
    }

    // Sort expenses by date (newest first)
    final sortedExpenses = List<Expense>.from(expenses)
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Details',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableHeader('Date'),
                _tableHeader('Category'),
                _tableHeader('Note'),
                _tableHeader('Amount', align: pw.TextAlign.right),
              ],
            ),
            // Data rows
            ...sortedExpenses.map((expense) => pw.TableRow(
              children: [
                _tableCell(DateFormat('dd/MM').format(expense.date)),
                _tableCell(expense.categoryName ?? 'Other'),
                _tableCell(expense.note ?? '-'),
                _tableCell(
                  'Rs.${expense.amount.toStringAsFixed(2)}',
                  align: pw.TextAlign.right,
                  isBold: true,
                ),
              ],
            )),
            // Total row
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _tableCell(''),
                _tableCell(''),
                _tableCell('Total', isBold: true, align: pw.TextAlign.right),
                _tableCell(
                  'Rs.${totalAmount.toStringAsFixed(2)}',
                  align: pw.TextAlign.right,
                  isBold: true,
                  color: PdfColors.blue800,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _tableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        textAlign: align,
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool isBold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isBold ? pw.FontWeight.bold : null,
          color: color,
        ),
        textAlign: align,
        maxLines: 2,
      ),
    );
  }
}
