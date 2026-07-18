import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../../view_models/providers/sales_provider.dart';
import '../../../view_models/services/database/database_services.dart'
    hide databaseServiceProvider;
import '../../../view_models/states/dashboard_state.dart';
import 'financial_report_pdf_generator.dart';

/// Orchestrates building the financial report PDF from the current dashboard
/// snapshot: pulls shop identity (name/logo) from the users box, renders the
/// PDF, writes it to a `financial_reports` folder and opens it. Returns the
/// saved file path; throws on failure so the caller can surface a message.
class FinancialReportService {
  static Future<String> buildSaveOpen({
    required WidgetRef ref,
    required DashboardState state,
    String? aiInsights,
  }) async {
    final dbService = ref.read(databaseServiceProvider);

    // Shop identity (best-effort — report still renders with defaults).
    String shopName = 'My Shop';
    String? ownerName;
    String? phoneNumber;
    String? shopAddress;
    Uint8List? shopLogo;
    try {
      final users = await dbService.getUsers();
      if (users.isNotEmpty) {
        final user = users.first;
        shopName = user.shopName;
        ownerName = user.ownerName;
        phoneNumber = user.phoneNumber;
        shopAddress = user.shopAddress;
        final logoPath = user.shopLogoPath;
        if (logoPath != null && logoPath.isNotEmpty) {
          final logoFile = File(logoPath);
          if (await logoFile.exists()) {
            shopLogo = await logoFile.readAsBytes();
          }
        }
      }
    } catch (_) {
      // Ignore — fall back to defaults.
    }

    final generator = FinancialReportPDFGenerator(
      state: state,
      shopName: shopName,
      shopLogo: shopLogo,
      ownerName: ownerName,
      phoneNumber: phoneNumber,
      shopAddress: shopAddress,
      aiInsights: aiInsights,
    );
    final pdf = generator.generatePDF();

    final directoryPath = await HiveService().directoryPath;
    final directory = Directory('$directoryPath/financial_reports');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final period = state.isYearlyView
        ? '${state.selectedMonth.year}'
        : DateFormat('yyyy_MM').format(state.selectedMonth);
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/financial_report_${period}_$stamp.pdf');
    await file.writeAsBytes(await pdf.save());

    await OpenFile.open(file.path);
    return file.path;
  }
}
