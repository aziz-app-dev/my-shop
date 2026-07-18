import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../view_models/states/dashboard_state.dart';

/// Builds a period financial report PDF from a [DashboardState] snapshot
/// (monthly or yearly). Mirrors the visual style of the customer report so the
/// whole app produces consistent documents. An optional [aiInsights] block is
/// rendered when the AI forecasting feature supplies a narrative.
class FinancialReportPDFGenerator {
  final DashboardState state;
  final String shopName;
  final Uint8List? shopLogo;
  final String? ownerName;
  final String? phoneNumber;
  final String? shopAddress;

  /// Optional AI-generated narrative + forecast summary (Stage 3).
  final String? aiInsights;

  FinancialReportPDFGenerator({
    required this.state,
    required this.shopName,
    this.shopLogo,
    this.ownerName,
    this.phoneNumber,
    this.shopAddress,
    this.aiInsights,
  });

  static const PdfColor _brand = PdfColor.fromInt(0xFFff6701);

  bool get _yearly => state.isYearlyView;

  String get _periodLabel => _yearly
      ? 'Year ${state.selectedMonth.year}'
      : DateFormat('MMMM yyyy').format(state.selectedMonth);

  String _rs(double v) => 'Rs.${v.toStringAsFixed(0)}';

  pw.Document generatePDF() {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (context) => _buildHeader(),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummarySection(),
          pw.SizedBox(height: 14),
          _buildReceivablesSection(),
          pw.SizedBox(height: 14),
          if (aiInsights != null && aiInsights!.trim().isNotEmpty) ...[
            _buildAiInsights(),
            pw.SizedBox(height: 14),
          ],
          if (_yearly && state.monthlyBreakdown.isNotEmpty) ...[
            _buildMonthlyBreakdown(),
            pw.SizedBox(height: 14),
          ],
          _buildTopCustomers(),
          pw.SizedBox(height: 14),
          _buildTopSellingItems(),
          pw.SizedBox(height: 14),
          _buildCategoryProfit(),
          pw.SizedBox(height: 14),
          _buildExpenseBreakdown(),
        ],
      ),
    );
    return pdf;
  }

  // ---------------------------------------------------------------- header

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
                  pw.Text(shopName,
                      style: pw.TextStyle(
                          fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  if (ownerName != null && ownerName!.isNotEmpty)
                    pw.Text(ownerName!, style: const pw.TextStyle(fontSize: 10)),
                  if (phoneNumber != null && phoneNumber!.isNotEmpty)
                    pw.Text('Phone: $phoneNumber',
                        style: const pw.TextStyle(fontSize: 10)),
                  if (shopAddress != null && shopAddress!.isNotEmpty)
                    pw.Text(shopAddress!,
                        style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('FINANCIAL REPORT',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _brand)),
              pw.SizedBox(height: 3),
              pw.Text(_periodLabel,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 3),
              pw.Text(
                  'Generated: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
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
          pw.Text('Financial Report - $_periodLabel',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- summary

  pw.Widget _buildSummarySection() {
    final sales = _yearly ? state.totalSalesThisYear : state.totalSalesThisMonth;
    final expenses =
        _yearly ? state.totalExpensesThisYear : state.totalOutflowThisMonth;
    final netProfit =
        _yearly ? state.netProfitThisYear : state.netProfit;
    final received =
        _yearly ? state.totalReceivedThisYear : state.totalReceivedThisMonth;
    final pending =
        _yearly ? state.totalPendingThisYear : state.totalPendingThisMonth;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Period Summary'),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _summaryCard('Total Sales', _rs(sales), PdfColors.blue700,
                PdfColors.blue50),
            pw.SizedBox(width: 8),
            _summaryCard('Total Outflow', _rs(expenses), PdfColors.orange800,
                PdfColors.orange50),
            pw.SizedBox(width: 8),
            _summaryCard(
                'Net Profit',
                _rs(netProfit),
                netProfit >= 0 ? PdfColors.green700 : PdfColors.red700,
                netProfit >= 0 ? PdfColors.green50 : PdfColors.red50),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _summaryCard('Payments Received', _rs(received),
                PdfColors.green700, PdfColors.green50),
            pw.SizedBox(width: 8),
            _summaryCard('Pending (period)', _rs(pending),
                pending > 0 ? PdfColors.red700 : PdfColors.green700,
                pending > 0 ? PdfColors.red50 : PdfColors.green50),
            pw.SizedBox(width: 8),
            _summaryCard('Transactions', '${state.totalTransactions}',
                PdfColors.grey800, PdfColors.grey100),
          ],
        ),
        pw.SizedBox(height: 8),
        // Gross profit / margin line (monthly only – yearly getter differs)
        if (!_yearly)
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                _inlineStat('Gross Profit', _rs(state.grossProfit)),
                _inlineStat('Gross Margin',
                    '${state.grossProfitMargin.toStringAsFixed(1)}%'),
                _inlineStat('Total Expenses',
                    _rs(state.totalExpensesThisMonth)),
              ],
            ),
          ),
      ],
    );
  }

  pw.Widget _buildReceivablesSection() {
    final byMethod = state.salesByPaymentMethod;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Receivables & Payment Methods'),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.red200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Outstanding (all-time)',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Text(_rs(state.totalPendingReceivables),
                        style: pw.TextStyle(
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red700)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Sales by Payment Method',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    if (byMethod.isEmpty)
                      pw.Text('No data',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey600))
                    else
                      ...byMethod.entries.map((e) => pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(e.key,
                                  style: const pw.TextStyle(fontSize: 10)),
                              pw.Text(_rs(e.value),
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold)),
                            ],
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAiInsights() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _brand),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('AI Insights & Forecast',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: _brand)),
          pw.SizedBox(height: 6),
          pw.Text(aiInsights!, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildMonthlyBreakdown() {
    final rows = state.monthlyBreakdown;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('Monthly Breakdown'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.4),
            1: const pw.FlexColumnWidth(1.2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.2),
            4: const pw.FlexColumnWidth(1.2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _cell('Month', header: true),
                _cell('Sales', header: true, align: pw.TextAlign.right),
                _cell('Expenses', header: true, align: pw.TextAlign.right),
                _cell('Received', header: true, align: pw.TextAlign.right),
                _cell('Pending', header: true, align: pw.TextAlign.right),
              ],
            ),
            ...rows.map((m) => pw.TableRow(children: [
                  _cell(m.monthName),
                  _cell(_rs(m.sales), align: pw.TextAlign.right),
                  _cell(_rs(m.expenses), align: pw.TextAlign.right),
                  _cell(_rs(m.received), align: pw.TextAlign.right),
                  _cell(_rs(m.pending), align: pw.TextAlign.right),
                ])),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTopCustomers() {
    final rows = state.topCustomersByRevenue.take(10).toList();
    return _tableSection(
      'Top Customers by Revenue',
      ['Customer', 'Transactions', 'Revenue'],
      const [pw.FlexColumnWidth(3), pw.FlexColumnWidth(1.4), pw.FlexColumnWidth(1.6)],
      rows
          .map((c) => [
                _cell(c.name),
                _cell('${c.transactionCount}', align: pw.TextAlign.center),
                _cell(_rs(c.totalRevenue), align: pw.TextAlign.right),
              ])
          .toList(),
      emptyText: 'No customer sales in this period',
    );
  }

  pw.Widget _buildTopSellingItems() {
    final rows = state.topSellingItems.take(10).toList();
    return _tableSection(
      'Top Selling Items',
      ['Item', 'Qty', 'Revenue', 'Profit'],
      const [
        pw.FlexColumnWidth(2.6),
        pw.FlexColumnWidth(1),
        pw.FlexColumnWidth(1.4),
        pw.FlexColumnWidth(1.4),
      ],
      rows
          .map((i) => [
                _cell(i.name),
                _cell('${i.quantitySold}', align: pw.TextAlign.center),
                _cell(_rs(i.totalRevenue), align: pw.TextAlign.right),
                _cell(_rs(i.totalProfit), align: pw.TextAlign.right),
              ])
          .toList(),
      emptyText: 'No item sales in this period',
    );
  }

  pw.Widget _buildCategoryProfit() {
    final rows = state.profitByCategory.take(10).toList();
    return _tableSection(
      'Profit by Category',
      ['Category', 'Revenue', 'Cost', 'Profit', 'Margin'],
      const [
        pw.FlexColumnWidth(2),
        pw.FlexColumnWidth(1.3),
        pw.FlexColumnWidth(1.3),
        pw.FlexColumnWidth(1.3),
        pw.FlexColumnWidth(1),
      ],
      rows
          .map((c) => [
                _cell(c.category),
                _cell(_rs(c.revenue), align: pw.TextAlign.right),
                _cell(_rs(c.cost), align: pw.TextAlign.right),
                _cell(_rs(c.profit), align: pw.TextAlign.right),
                _cell('${c.profitMargin.toStringAsFixed(0)}%',
                    align: pw.TextAlign.right),
              ])
          .toList(),
      emptyText: 'No category data',
    );
  }

  pw.Widget _buildExpenseBreakdown() {
    final entries = state.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _tableSection(
      'Expenses by Category',
      ['Category', 'Amount'],
      const [pw.FlexColumnWidth(3), pw.FlexColumnWidth(1.6)],
      entries
          .map((e) => [
                _cell(e.key),
                _cell(_rs(e.value), align: pw.TextAlign.right),
              ])
          .toList(),
      emptyText: 'No expenses in this period',
    );
  }

  // ------------------------------------------------------------- ui atoms

  pw.Widget _sectionTitle(String text) => pw.Text(text,
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold));

  pw.Widget _summaryCard(
      String title, String value, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700)),
            pw.SizedBox(height: 5),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  pw.Widget _inlineStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
      ],
    );
  }

  pw.Widget _tableSection(
    String title,
    List<String> headers,
    List<pw.TableColumnWidth> widths,
    List<List<pw.Widget>> rows, {
    String emptyText = 'No data',
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle(title),
        pw.SizedBox(height: 8),
        if (rows.isEmpty)
          pw.Text(emptyText,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600))
        else
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: widths.asMap(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  for (var i = 0; i < headers.length; i++)
                    _cell(headers[i],
                        header: true,
                        align: i == 0
                            ? pw.TextAlign.left
                            : (headers[i] == 'Transactions' || headers[i] == 'Qty'
                                ? pw.TextAlign.center
                                : pw.TextAlign.right)),
                ],
              ),
              ...rows.map((cells) => pw.TableRow(children: cells)),
            ],
          ),
      ],
    );
  }

  pw.Widget _cell(String text,
      {bool header = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 9 : 8,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }
}
