import 'dart:io';

import 'package:desktopapp/res/components/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

import '../../../res/assets/image_assets.dart';
import '../../../res/components/app_bar_widget.dart';
import '../../../res/components/app_flushbar.dart';
import '../../../res/components/app_icon.dart';
import '../../../view_models/providers/expense_provider.dart';
import '../../../view_models/providers/settings_provider.dart';
import '../../../view_models/services/database/database_services.dart';
import 'expense_dialogs.dart';
import 'expense_pdf_generator.dart';

class ExpenseAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isMobile;
  final VoidCallback? openDrawer;

  const ExpenseAppBar({super.key, this.isMobile = false, this.openDrawer});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider);

    return AppBarWidget.customAppBar(
      title: 'Expenses',
      context: context,
      automaticallyImplyLeading: isMobile,
      backIcon: isMobile ? TablerIcons.menu_2 : null,
      leadingOnTap: isMobile ? openDrawer : null,
      actions: [
        if (!isMobile) ...[
          SizedBox(
            width: 175.spMin,
            child: AppButton().iconButton(
              height: 35.spMin,
              fontSize: 14.spMin,
              text: "Add Expense",
              onPressed:
                  () => ExpenseDialogs.showAddExpenseDialog(
                    context,
                    ref,
                    expenseState.categories,
                  ),
              ref: ref,
              icon: Icons.add,
              win11Icon: ImageAssets.win11Add,
            ),
          ),
        ],
        PopupMenuButton<String>(
          icon: AppIcon(
            size: 18.spMin,
            imgSize: 22.spMin,
            defaultIcon: Icons.more_vert,
            win11IconPath: ImageAssets.win11MenuVertical,
          ),
          onSelected: (value) async {
            if (value == 'filter') {
              ExpenseDialogs.showFilterDialog(context, ref, expenseState);
            } else if (value == 'add_category') {
              ExpenseDialogs.showAddCategoryDialog(context, ref);
            } else if (value == 'download_pdf') {
              await _generateAndDownloadPDF(context, ref);
            }
          },
          itemBuilder:
              (context) => [
                _menuItem(
                  icon: TablerIcons.filter,
                  text: 'Filter',
                  value: 'filter',
                  win11IconPath: ImageAssets.win11Filter,
                ),
                _menuItem(
                  icon: TablerIcons.category_plus,
                  text: 'Add Category',
                  value: 'add_category',
                  win11IconPath: ImageAssets.win11Category,
                ),
                const PopupMenuDivider(),
                _menuItem(
                  icon: TablerIcons.file_type_pdf,
                  text: 'Download Report',
                  value: 'download_pdf',
                  win11IconPath: ImageAssets.win11Pdf,
                ),
              ],
        ),

        // Add expense button (only for desktop)
      ],
    );
  }

  Future<void> _generateAndDownloadPDF(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final expenseState = ref.read(expenseProvider);
    final selectedMonth = expenseState.selectedMonth;
    final expenses = expenseState.selectedMonthExpenses;

    if (expenses.isEmpty) {
      if (context.mounted) {
        AppFlushbar.error(
          context,
          message:
              'No expenses for ${DateFormat('MMMM yyyy').format(selectedMonth)}',
        );
      }
      return;
    }

    try {
      // Show loading indicator
      if (context.mounted) {
        AppFlushbar.info(
          context,
          message: 'Generating PDF report...',
          duration: const Duration(seconds: 2),
        );
      }

      // Load user data directly from database
      final dbService = DatabaseService();
      final users = await dbService.getUsers();
      final String shopName =
          users.isNotEmpty ? users.first.shopName : 'My Shop';
      final String? ownerName = users.isNotEmpty ? users.first.ownerName : null;

      // Generate PDF
      final pdfGenerator = ExpensePDFGenerator(
        expenses: expenses,
        selectedMonth: selectedMonth,
        shopName: shopName,
        ownerName: ownerName,
        totalAmount: expenseState.currentMonthTotal,
        expensesByCategory: expenseState.expensesByCategory,
      );
      final pdf = pdfGenerator.generatePDF();

      // Get directory path from settings
      final settingsState = ref.read(settingsProvider);
      String directoryPath = settingsState.directoryPath;

      // If no custom path is set, use default
      if (directoryPath.isEmpty) {
        directoryPath = await dbService.getCurrentHivePath();
      }

      // Create expenses folder inside the configured directory
      final directory = Directory('$directoryPath/expenses');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final monthStr = DateFormat('yyyy_MM').format(selectedMonth);
      final fileName =
          'expense_report_${monthStr}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('$directoryPath/expenses/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        AppFlushbar.success(
          context,
          message: 'PDF saved successfully',
          actionText: 'Open',
          onActionPressed: () async {
            await OpenFile.open(file.path);
          },
        );
      }

      // Automatically open the PDF
      await OpenFile.open(file.path);
    } catch (e) {
      if (context.mounted) {
        AppFlushbar.error(context, message: 'Error generating PDF: $e');
      }
    }
  }
}

PopupMenuItem<String> _menuItem({
  required IconData icon,
  required String win11IconPath,
  required String text,
  required String value,
}) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        AppIcon(
          size: 18.spMin,
          defaultIcon: icon,
          win11IconPath: win11IconPath,
        ),
        SizedBox(width: 12.w),
        Text(text, style: TextStyle(fontSize: 14.spMin)),
      ],
    ),
  );
}
