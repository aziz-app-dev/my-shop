import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_icon.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../view_models/providers/bills_provider.dart';
import '../bills_details.dart';

class DataTableWidget extends ConsumerWidget {
  const DataTableWidget({super.key});

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 750;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 750 &&
      MediaQuery.of(context).size.width < 1100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsState = ref.watch(billsProvider);
    final billsNotifier = ref.read(billsProvider.notifier);
    final isMobileView = isMobile(context);
    final isTabletView = isTablet(context);
    final bills = billsState.filteredBills;
    final startIndex = (billsState.currentPage - 1) * billsState.recordsPerPage;
    final endIndex =
        (startIndex + billsState.recordsPerPage) > bills.length
            ? bills.length
            : (startIndex + billsState.recordsPerPage);
    final paginatedBills =
        bills.isNotEmpty ? bills.sublist(startIndex, endIndex) : [];

    if (isMobileView) {
      return ListView.builder(
        itemCount: paginatedBills.length,
        itemBuilder: (context, index) {
          final bill = paginatedBills[index];
          final isSelected = billsState.selectedBills[bill.id] ?? false;
          return Card(
            margin: EdgeInsets.symmetric(
              vertical: 4.spMin,
              horizontal: 12.spMin,
            ),
            color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
            child: InkWell(
              hoverColor: Colors.transparent,
              onTap: () {
                // If we're in selection mode, toggle selection on tap
                if (billsState.isSelectionMode) {
                  billsNotifier.toggleBillSelection(bill.id, !isSelected);
                } else {
                  // Normal tap behavior - navigate to details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillDetailScreen(bill: bill),
                    ),
                  );
                }
              },
              onLongPress: () {
                // Enable selection mode and select this bill
                billsNotifier.toggleBillSelection(bill.id, true);
              },
              child: Padding(
                padding: EdgeInsets.all(6.spMin),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First Row - Date, Time, and Checkbox
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //! Date and Time section
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              defaultIcon: Icons.calendar_today,
                              win11IconPath: ImageAssets.win11CalendarPlus,
                              size: 10.spMin,
                              color:
                                  (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.dIconColor
                                      : AppColors.primary),
                            ),
                            SizedBox(width: 2.spMin),
                            xsText(
                              text: DateFormat(
                                'dd MMM yyyy',
                              ).format(bill.dateTime),
                            ),
                            SizedBox(width: 6.spMin),
                            AppIcon(
                              defaultIcon: Icons.access_time,
                              win11IconPath: ImageAssets.win11DeliveryTime,
                              size: 10.spMin,
                              color:
                                  (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.dIconColor
                                      : AppColors.primary),
                            ),
                            SizedBox(width: 2.spMin),
                            xsText(
                              text: DateFormat('HH:mm').format(bill.dateTime),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              defaultIcon:
                                  bill.status != 'Paid'
                                      ? TablerIcons.parking_circle
                                      : Icons.check_circle,
                              win11IconPath:
                                  bill.status != 'Paid'
                                      ? ImageAssets.win11Pending
                                      : ImageAssets.win11Done,
                              size: 12.spMin,
                              color:
                                  bill.status == 'Paid'
                                      ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.green)
                                      : bill.status == 'Pending'
                                      ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.orange)
                                      : Colors.red,
                            ),
                            SizedBox(width: 2.w),
                            smText(
                              text: bill.status ?? 'Pending',

                              color:
                                  bill.status == 'Paid'
                                      ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.green)
                                      : bill.status == 'Pending'
                                      ? (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white
                                          : Colors.orange)
                                      : Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 4.spMin),

                    //! Second Row - Customer Name and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Customer Name with flexible constraint
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(
                                defaultIcon: Icons.person,
                                win11IconPath: ImageAssets.win11TestAccount,
                                size: 14.spMin,
                                color:
                                    (Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppColors.dIconColor
                                        : AppColors.primary),
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: mdTextBold(
                                  text: bill.customerName ?? 'N/A',
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Status
                        smTextBold(
                          text: 'Rs.${bill.totalAmount.toStringAsFixed(2)}',
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    //! Third Row - Items count and Payment method
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //! Items count
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppIcon(
                              defaultIcon: TablerIcons.shopping_bag_check,
                              win11IconPath: ImageAssets.win11Checkout,
                              size: 14.spMin,
                              color:
                                  (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.orange),
                            ),
                            SizedBox(width: 4.w),
                            xsText(text: '${bill.items.length} items'),
                          ],
                        ),
                        //  Payment method
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (bill.paymentMethod != null &&
                                bill.paymentMethod!.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(left: 8.w),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.spMin,
                                    vertical: 2.spMin,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? AppColors.dScafoldColor
                                            : AppColors.lBodyColor),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: xsText(
                                    text: bill.paymentMethod ?? '',
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // Selection mode indicator
                    if (billsState.isSelectionMode && isSelected)
                      Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppIcon(
                              defaultIcon: Icons.check_circle,
                              win11IconPath: ImageAssets.win11Done,
                              size: 14.spMin,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Selected',
                              style: TextStyle(
                                fontSize: 10.spMin,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: DataTable2(
        dividerThickness: 0,
        headingCheckboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : Colors.transparent,
          ),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: BorderSide(color: Colors.white, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        datarowCheckboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected)
                    ? AppColors.primary
                    : Colors.transparent,
          ),
          checkColor: WidgetStateProperty.all(Colors.white),
          side: BorderSide(
            color:
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
            width: 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        columnSpacing:
            isMobileView
                ? 4.w
                : isTabletView
                ? 6.w
                : 8.w,

        horizontalMargin: 4.w,
        minWidth: MediaQuery.of(context).size.width * 0.60,
        headingRowHeight: 45.spMin,
        dataRowHeight: 40.spMin,
        headingRowDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),

        dataTextStyle: TextStyle(fontSize: 12.spMin),
        headingRowColor: WidgetStateColor.resolveWith(
          (states) => AppColors.primaryLight2,
        ),
        columns: [
          DataColumn2(
            label: const DataTableHeaderCell(
              win11Icon: ImageAssets.win11Bill,
              icon: Icons.receipt,
              title: 'Bill ID',
            ),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: const DataTableHeaderCell(
              win11Icon: ImageAssets.win11CalendarPlus,

              icon: Icons.calendar_today,
              title: 'Date',
            ),
            size: ColumnSize.M,
            onSort:
                (columnIndex, ascending) =>
                    billsNotifier.sortTable(columnIndex, ascending),
          ),
          DataColumn2(
            label: const DataTableHeaderCell(
              win11Icon: ImageAssets.win11DeliveryTime,

              icon: Icons.access_time,
              title: 'Time',
            ),
            size: ColumnSize.S,
          ),
          DataColumn2(
            label: const DataTableHeaderCell(
              win11Icon: ImageAssets.win11TestAccount,

              icon: Icons.person,
              title: 'Customer',
            ),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: const DataTableHeaderCell(
              win11Icon: ImageAssets.win11List,

              icon: Icons.list,
              title: 'Items',
            ),
            size: ColumnSize.S,
            numeric: true,
          ),
          DataColumn2(
            label: const DataTableHeaderCell(
              win11Icon: ImageAssets.win11DollarBag,

              icon: Icons.attach_money,
              title: 'Total',
            ),
            size: ColumnSize.S,
            numeric: true,
          ),
          DataColumn2(
            label: const DataTableHeaderCell(
              win11Icon: ImageAssets.win11Cash,

              icon: Icons.payment,
              title: 'Method',
            ),
            size: ColumnSize.M,
          ),
          DataColumn2(
            label: const DataTableHeaderCell(
              win11Icon: ImageAssets.win11Done,

              icon: Icons.check_circle,
              title: 'Status',
            ),
            size: ColumnSize.S,
          ),
        ],
        rows:
            paginatedBills.asMap().entries.map((entry) {
              final index = entry.key;
              final bill = entry.value;
              final isSelected = billsState.selectedBills[bill.id] ?? false;
              return DataRow2(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      index.isEven
                          ? Colors.transparent
                          : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.grey800
                              : AppColors.primary.withValues(alpha: 0.1)),
                ),
                color: WidgetStateColor.resolveWith(
                  (states) =>
                      index.isEven
                          ? Colors.transparent
                          : (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.grey800
                              : AppColors.primary.withValues(alpha: 0.1)),
                ),
                selected: isSelected,
                onSelectChanged:
                    (value) =>
                        billsNotifier.toggleBillSelection(bill.id, value),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillDetailScreen(bill: bill),
                    ),
                  );
                },
                cells: [
                  DataCell(
                    TableDataCellText(text: '#${bill.id.substring(0, 8)}'),
                  ),
                  DataCell(
                    TableDataCellText(
                      text: DateFormat('dd MMM yyyy').format(bill.dateTime),
                    ),
                  ),
                  DataCell(
                    TableDataCellText(
                      text: DateFormat('HH:mm').format(bill.dateTime),
                    ),
                  ),
                  DataCell(
                    TableDataCellText(
                      text: bill.customerName ?? 'N/A',
                      tooltip: true,
                    ),
                  ),
                  DataCell(TableDataCellText(text: '${bill.items.length}')),
                  DataCell(
                    TableDataCellText(
                      text: 'Rs.${bill.totalAmount.toStringAsFixed(2)}',
                      color: Colors.green.shade700,
                    ),
                  ),
                  DataCell(
                    TableDataCellText(
                      text: bill.paymentMethod ?? 'N/A',
                      tooltip: true,
                    ),
                  ),
                  DataCell(
                    TableDataCellText(
                      text: bill.status ?? 'Pending',
                      color:
                          bill.status == 'Paid'
                              ? Colors.green
                              : bill.status == 'Pending'
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                ],
              );
            }).toList(),
        sortColumnIndex: billsState.sortColumnIndex,
        sortAscending: billsState.sortAscending,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}

class DataTableHeaderCell extends StatelessWidget {
  final IconData icon;
  final String win11Icon;
  final String title;

  const DataTableHeaderCell({
    super.key,
    required this.icon,
    required this.win11Icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            defaultIcon: icon,
            win11IconPath: win11Icon,
            size: 15.spMin,
            color: Colors.white,
          ),
          SizedBox(width: 2.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.spMin,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class TableDataCellText extends StatelessWidget {
  final String text;
  final Color? color;
  final bool tooltip;

  const TableDataCellText({
    super.key,
    required this.text,
    this.color,
    this.tooltip = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12.spMin,
        color:
            color ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black),
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    );
    return Center(
      child: tooltip ? Tooltip(message: text, child: content) : content,
    );
  }
}
