// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_flushbar.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../res/components/text_field_widget.dart';
import '../../view_models/providers/bills_provider.dart';
import '../../view_models/providers/customer_prvider.dart';
import '../../view_models/providers/sales_provider.dart';
import '../../view_models/providers/customer_details_provider.dart';
import '../../view_models/services/database/database_services.dart'
    hide databaseServiceProvider;
import '../bills/bills_details.dart';
import '../home/rapper.dart';
import 'widgets/customer_report_pdf_generator.dart';

class CustomerDetailsScreen extends ConsumerStatefulWidget {
  final Customer customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  CustomerDetailsScreenState createState() => CustomerDetailsScreenState();
}

class CustomerDetailsScreenState extends ConsumerState<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _addressController = TextEditingController(text: widget.customer.address);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    ref.read(customerDetailsProvider.notifier).toggleEditMode();
  }

  Future<void> _updateCustomer() async {
    if (_formKey.currentState!.validate()) {
      final updatedCustomer = widget.customer.copyWith(
        name: _nameController.text,
        address: _addressController.text,
        phoneNumber: _phoneController.text,
      );
      await ref.read(databaseServiceProvider).updateCustomer(updatedCustomer);
      ref.read(customersProvider.notifier).refresh();
      ref.read(customerDetailsProvider.notifier).setEditMode(false);
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: mdTextBold(text: 'Delete Customer'),
            content: mdText(
              text: 'Are you sure you want to delete this customer?',
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: smText(text: 'Cancel'),
                    ),
                  ),
                  Expanded(
                    child: AppButton().primaryButton(
                      height: 35.spMin,
                      color: AppColors.error,
                      text: 'Delete',
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
    if (confirm == true) {
      await ref
          .read(databaseServiceProvider)
          .deleteCustomer(widget.customer.id);
      ref.read(customersProvider.notifier).refresh();
      Navigator.pop(context);
    }
  }

  // /// Check if running on mobile platform
  // bool get _isMobilePlatform {
  //   if (kIsWeb) return false;
  //   return Platform.isAndroid || Platform.isIOS;
  // }

  /// Generate and open/share customer report PDF
  Future<void> _generateCustomerReportPDF() async {
    try {
      // Get bills for this customer
      final billsState = ref.read(billsProvider);
      final customerBills =
          billsState.allBills
              .where((bill) => bill.customerId == widget.customer.id)
              .toList();

      // Calculate totals
      final billsData = _processBillsData(customerBills);
      final totalSpending = billsData['totalSpending'] as double;
      final totalPending = billsData['pendingTotal'] as double;

      // Get shop info
      final dbService = ref.read(databaseServiceProvider);
      final users = await dbService.getUsers();

      String shopName = 'Shop';
      Uint8List? shopLogo;
      String? ownerName;
      String? phoneNumber;
      String? shopAddress;

      if (users.isNotEmpty) {
        final user = users.first;
        shopName = user.shopName;
        ownerName = user.ownerName;
        phoneNumber = user.phoneNumber;
        shopAddress = user.shopAddress;

        // Load shop logo if exists
        if (user.shopLogoPath != null && user.shopLogoPath!.isNotEmpty) {
          final logoFile = File(user.shopLogoPath!);
          if (await logoFile.exists()) {
            shopLogo = await logoFile.readAsBytes();
          }
        }
      }

      // Generate PDF
      final pdfGenerator = CustomerReportPDFGenerator(
        customer: widget.customer,
        bills: customerBills,
        shopName: shopName,
        shopLogo: shopLogo,
        ownerName: ownerName,
        phoneNumber: phoneNumber,
        shopAddress: shopAddress,
        totalSpending: totalSpending,
        totalPending: totalPending,
      );

      final pdf = pdfGenerator.generatePDF();

      // Save to file
      final directoryPath = await HiveService().directoryPath;
      final directory = Directory('$directoryPath/customer_reports');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final fileName =
          'customer_report_${widget.customer.name.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Open the file
      await OpenFile.open(file.path);

      AppFlushbar.success(
        context,
        message: 'Customer report generated successfully',
      );
    } catch (e) {
      AppFlushbar.error(
        context,
        message: 'Failed to generate report: ${e.toString()}',
      );
    }
  }

  Widget _buildMobileView(WidgetRef ref) {
    final billsState = ref.watch(billsProvider);
    if (billsState.error != null) {
      return Center(child: mdText(text: 'Error: ${billsState.error}'));
    }
    if (billsState.allBills.isEmpty && billsState.filteredBills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final customerBills =
        billsState.allBills
            .where((bill) => bill.customerId == widget.customer.id)
            .toList();

    final billsData = _processBillsData(customerBills);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.spMin, vertical: 12.spMin),
      child: Column(
        spacing: 12.spMin,
        children: [
          _buildCustomerDetailsCard(
            totalSpending: billsData['totalSpending'],
            totalPending: billsData['pendingTotal'],
          ),
          _buildBillsCard(
            billsData['completedBills'],
            billsData['pendingBills'],
            billsData['completedTotal'],
            billsData['pendingTotal'],
            customerBills.length,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletView(WidgetRef ref) {
    final billsState = ref.watch(billsProvider);
    if (billsState.error != null) {
      return Center(child: mdText(text: 'Error: ${billsState.error}'));
    }
    if (billsState.allBills.isEmpty && billsState.filteredBills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final customerBills =
        billsState.allBills
            .where((bill) => bill.customerId == widget.customer.id)
            .toList();

    final billsData = _processBillsData(customerBills);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.spMin, vertical: 12.spMin),
      child: Column(
        spacing: 16.spMin,
        children: [
          _buildCustomerDetailsCard(
            totalSpending: billsData['totalSpending'],
            totalPending: billsData['pendingTotal'],
          ),
          _buildBillsCard(
            billsData['completedBills'],
            billsData['pendingBills'],
            billsData['completedTotal'],
            billsData['pendingTotal'],
            customerBills.length,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopView(WidgetRef ref) {
    final billsState = ref.watch(billsProvider);
    if (billsState.error != null) {
      return Center(child: mdText(text: 'Error: ${billsState.error}'));
    }
    if (billsState.allBills.isEmpty && billsState.filteredBills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final customerBills =
        billsState.allBills
            .where((bill) => bill.customerId == widget.customer.id)
            .toList();

    final billsData = _processBillsData(customerBills);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.horizontalPaddingLg.spMin,
        vertical: AppSizes.verticalPaddingLg.spMin,
      ),
      child: Row(
        spacing: 16.spMin,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildCustomerDetailsCard(
              totalSpending: billsData['totalSpending'],
              totalPending: billsData['pendingTotal'],
            ),
          ),
          Expanded(
            flex: 5,
            child: _buildBillsCard(
              billsData['completedBills'],
              billsData['pendingBills'],
              billsData['completedTotal'],
              billsData['pendingTotal'],
              customerBills.length,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _processBillsData(List<Bill> customerBills) {
    const tolerance = 0.01;
    final completedBills =
        customerBills.where((bill) {
          final finalAmount = bill.totalAmount - bill.discount;
          final isCompleted = bill.paidAmount >= (finalAmount - tolerance);
          return isCompleted;
        }).toList();

    final pendingBills =
        customerBills.where((bill) {
          final finalAmount = bill.totalAmount - bill.discount;
          return bill.paidAmount < (finalAmount - tolerance);
        }).toList();

    final completedTotal = completedBills.fold<double>(
      0.0,
      (sum, bill) => sum + (bill.totalAmount - bill.discount),
    );

    final pendingTotal = pendingBills.fold<double>(0.0, (sum, bill) {
      final finalAmount = bill.totalAmount - bill.discount;
      return sum + (finalAmount - bill.paidAmount);
    });

    // Calculate total spending: ALL paid amounts across ALL bills
    final totalSpending = customerBills.fold<double>(
      0.0,
      (sum, bill) => sum + bill.paidAmount,
    );

    return {
      'completedBills': completedBills,
      'pendingBills': pendingBills,
      'completedTotal': completedTotal,
      'pendingTotal': pendingTotal,
      'totalSpending': totalSpending,
    };
  }

  Widget _buildBillsList(List<Bill> bills, bool isPendingTab) {
    // Calculate total paid for all bills in the list
    final totalPaid = bills.fold<double>(
      0.0,
      (sum, bill) => sum + bill.paidAmount,
    );
    // Calculate total pending only for pending tab
    final totalPending =
        isPendingTab
            ? bills.fold<double>(0.0, (sum, bill) {
              final finalAmount = bill.totalAmount - bill.discount;
              return sum + (finalAmount - bill.paidAmount);
            })
            : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards at the top
        if (bills.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.spMin, horizontal: 4.spMin),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.horizontalPaddingSm.w,
                      vertical: AppSizes.verticalPaddingSm.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusMd.r,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppIcon(
                              defaultIcon: Icons.payments_outlined,
                              win11IconPath: ImageAssets.win11Cash,
                              color: Colors.white,
                              size: 16.spMin,
                            ),
                            SizedBox(width: 3.spMin),
                            smTextBold(text: 'Total Paid'),
                          ],
                        ),
                        SizedBox(height: 6.spMin),
                        mdTextBold(
                          text: 'Rs.${totalPaid.toStringAsFixed(2)}',
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isPendingTab && totalPending > 0) ...[
                  SizedBox(width: 12.spMin),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.horizontalPaddingSm.w,
                        vertical: AppSizes.verticalPaddingSm.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.redAccent.withValues(alpha: 0.8),
                            Colors.red,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadiusMd.r,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppIcon(
                                defaultIcon: Icons.pending_actions_outlined,
                                win11IconPath: ImageAssets.win11Pending,
                                color: Colors.white,
                                size: 16.spMin,
                              ),
                              SizedBox(width: 3.spMin),
                              smTextBold(text: 'Total Pending'),
                            ],
                          ),
                          SizedBox(height: 6.spMin),
                          mdTextBold(
                            text: 'Rs.${totalPending.toStringAsFixed(2)}',
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Bills List
        Flexible(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.spMin),
            itemCount: bills.length,
            itemBuilder: (context, index) {
              final bill = bills[index];
              final subtotal = bill.items.fold<double>(
                0.0,
                (sum, item) =>
                    sum + (item.price * (bill.quantities[item.id] ?? 0)),
              );
              final finalAmount = bill.totalAmount - bill.discount;
              final pendingAmount = finalAmount - bill.paidAmount;
              final isPaid = pendingAmount <= 0;

              return GestureDetector(
                onDoubleTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillDetailScreen(bill: bill),
                    ),
                  );
                },
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 6.spMin),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    side: BorderSide(
                      color:
                          isPaid
                              ? AppColors.primary.withValues(alpha: 0.3)
                              : Colors.red.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: ExpansionTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppSizes.borderRadiusSm.r,
                      ),
                    ),
                    tilePadding: EdgeInsets.only(right: 6.spMin),
                    leading: Container(
                      height: 65.spMin,
                      width: 60.spMin,
                      decoration: BoxDecoration(
                        color:
                            isPaid
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: AppIcon(
                        defaultIcon:
                            isPaid ? Icons.check_circle : Icons.pending,
                        win11IconPath:
                            isPaid
                                ? ImageAssets.win11Done
                                : ImageAssets.win11Pending,
                        color: isPaid ? AppColors.primary : Colors.red,
                        size: 20.spMin,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            smTextBold(
                              text: 'Bill #${bill.id.substring(0, 8)}',
                            ),
                            // const Spacer(),
                            Padding(
                              padding: EdgeInsets.only(top: 4.spMin),
                              child: Row(
                                children: [
                                  AppIcon(
                                    defaultIcon: Icons.calendar_today,
                                    win11IconPath:
                                        ImageAssets.win11CalendarPlus,
                                    size: 12.spMin,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4.spMin),
                                  xsText(
                                    text: DateFormat(
                                      'dd MMM yyyy, HH:mm',
                                    ).format(bill.dateTime),
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.spMin,
                              vertical: 4.spMin,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isPaid
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.borderRadiusSm.r,
                              ),
                            ),
                            child: Center(
                              child: xsText(
                                text:
                                    isPaid
                                        ? 'PAID'
                                        : 'Rs.${pendingAmount.toStringAsFixed(2)} Due',
                                color: isPaid ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.spMin,
                          vertical: 12.spMin,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.dScafoldColor
                                  : AppColors.lBodyColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Table Header
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(11.r),
                                  topRight: Radius.circular(11.r),
                                ),
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 12.spMin,
                                horizontal: 12.spMin,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: smTextBold(text: 'Item'),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: smTextBold(
                                      text: 'Qty',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: smTextBold(
                                      text: 'Price',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: smTextBold(
                                      text: 'Total',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, thickness: 1),

                            // Table Items
                            ...bill.items.asMap().entries.map((entry) {
                              final item = entry.value;
                              final itemIndex = entry.key;
                              final quantity = bill.quantities[item.id] ?? 0;
                              final itemSubtotal = item.price * quantity;
                              return Container(
                                color:
                                    itemIndex.isEven
                                        ? Colors.transparent
                                        : Colors.grey.withValues(alpha: 0.05),
                                padding: EdgeInsets.symmetric(
                                  vertical: 10.spMin,
                                  horizontal: 12.spMin,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: smText(
                                        text: item.name,
                                        maxLines: 2,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: smText(
                                        text: '$quantity',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: smText(
                                        text:
                                            'Rs.${item.price.toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: smText(
                                        text:
                                            'Rs.${itemSubtotal.toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            Divider(height: 1, thickness: 1),

                            // Bill Summary
                            Container(
                              padding: EdgeInsets.all(12.spMin),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Subtotal
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 6.spMin),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        smText(text: 'Subtotal:'),
                                        smText(
                                          text:
                                              'Rs.${subtotal.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Discount
                                  if (bill.discount > 0)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 6.spMin),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          smText(
                                            text: 'Discount:',
                                            color: Colors.green,
                                          ),
                                          smText(
                                            text:
                                                '- Rs.${bill.discount.toStringAsFixed(2)}',
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                  Divider(),
                                  // Total (Subtotal - Discount)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8.spMin),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        mdTextBold(text: 'Total:'),
                                        mdTextBold(
                                          text:
                                              'Rs.${finalAmount.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Paid Amount
                                  if (bill.paidAmount > 0)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 6.spMin),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          smText(
                                            text: 'Paid:',
                                            color: Colors.green,
                                          ),
                                          smText(
                                            text:
                                                'Rs.${bill.paidAmount.toStringAsFixed(2)}',
                                            color: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Amount Due/Pending
                                  if (pendingAmount > 0) ...[
                                    Divider(),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12.spMin,
                                        vertical: 8.spMin,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          8.r,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          smTextBold(
                                            text: 'Amount Due:',
                                            color: Colors.red,
                                          ),
                                          smTextBold(
                                            text:
                                                'Rs.${pendingAmount.toStringAsFixed(2)}',
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetailsCard({
    double totalSpending = 0.0,
    double totalPending = 0.0,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      ),
      child: Column(
        children: [
          // Gradient Header
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.horizontalPaddingSm.w,
              vertical: AppSizes.verticalPaddingSm.h,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSizes.borderRadiusMd.r),
                topRight: Radius.circular(AppSizes.borderRadiusMd.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.spMin),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusMd.r,
                    ),
                  ),
                  child: AppIcon(
                    defaultIcon: Icons.person,
                    win11IconPath: ImageAssets.win11People,
                    color: Colors.white,
                    size: 20.spMin,
                  ),
                ),
                SizedBox(width: 6.spMin),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      lgTextBold(text: 'Customer Details', color: Colors.white),
                      SizedBox(height: 2.spMin),
                      smText(
                        text: 'ID: ${widget.customer.id.substring(0, 8)}',
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(10.spMin),
            child:
                ref.watch(customerDetailsProvider).isEditing
                    ? Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: _nameController,
                            label: 'Name',
                            hintText: 'Enter customer name',
                            prefixIcon: AppIcon(
                              defaultIcon: Icons.person_outline,
                              win11IconPath: ImageAssets.win11People,
                              size: 20.spMin,
                            ),
                            filled: true,
                            validator:
                                (value) =>
                                    value!.isEmpty ? 'Name is required' : null,
                          ),
                          SizedBox(height: 6.spMin),
                          CustomTextField(
                            controller: _addressController,
                            label: 'Address',
                            hintText: 'Enter customer address',
                            prefixIcon: AppIcon(
                              defaultIcon: Icons.location_on_outlined,
                              win11IconPath: ImageAssets.win11Location,
                              size: 20.spMin,
                            ),
                            filled: true,
                          ),
                          SizedBox(height: 12.spMin),
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            hintText: 'Enter phone number',
                            prefixIcon: AppIcon(
                              defaultIcon: Icons.phone_outlined,
                              win11IconPath: ImageAssets.win11Phone,
                              size: 20.spMin,
                            ),
                            filled: true,
                            keyboardType: TextInputType.phone,
                          ),
                          SizedBox(height: 20.spMin),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _updateCustomer,
                                  icon: AppIcon(
                                    defaultIcon: Icons.save,
                                    win11IconPath: ImageAssets.win11Save,
                                    size: 18.spMin,
                                  ),
                                  label: smTextBold(text: 'Save Changes'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.spMin,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.spMin),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _toggleEditMode,
                                  icon: AppIcon(
                                    defaultIcon: Icons.cancel,
                                    win11IconPath: ImageAssets.win11Cancel,
                                    size: 18.spMin,
                                  ),
                                  label: smTextBold(text: 'Cancel'),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.spMin,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        infoRow(
                          context,
                          "Name",
                          widget.customer.name,
                          Icons.person_outline,
                          win11IconPath: ImageAssets.win11People,
                        ),
                        SizedBox(height: 10.spMin),
                        infoRow(
                          context,
                          "Address",
                          widget.customer.address.isEmpty
                              ? 'N/A'
                              : widget.customer.address,
                          Icons.location_on_outlined,
                          win11IconPath: ImageAssets.win11Location,
                        ),
                        SizedBox(height: 10.spMin),
                        infoRow(
                          context,
                          "Phone",
                          widget.customer.phoneNumber.isEmpty
                              ? 'N/A'
                              : widget.customer.phoneNumber,
                          Icons.phone_outlined,
                          win11IconPath: ImageAssets.win11Phone,
                        ),
                        SizedBox(height: 10.spMin),
                        infoRow(
                          context,
                          "Total Visits",
                          widget.customer.visitCount.toString(),
                          Icons.shopping_bag_outlined,
                          win11IconPath: ImageAssets.win11Checkout,
                        ),
                        SizedBox(height: 10.spMin),
                        infoRow(
                          context,
                          "Total Spending",
                          'Rs.${totalSpending.toStringAsFixed(2)}',
                          Icons.attach_money_outlined,
                          win11IconPath: ImageAssets.win11DollarBag,
                        ),
                        SizedBox(height: 10.spMin),
                        infoRow(
                          context,
                          "Pending Amount",
                          'Rs.${totalPending.toStringAsFixed(2)}',
                          Icons.pending_actions_outlined,
                          win11IconPath: ImageAssets.win11Pending,
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsCard(
    List<Bill> completedBills,
    List<Bill> pendingBills,
    double completedTotal,
    double pendingTotal,
    int totalBillsCount,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with gradient
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.horizontalPaddingSm.w,
              vertical: AppSizes.horizontalPaddingSm.h,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSizes.borderRadiusMd.r),
                topRight: Radius.circular(AppSizes.borderRadiusMd.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.spMin),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusMd.r,
                    ),
                  ),
                  child: AppIcon(
                    defaultIcon: Icons.receipt_long,
                    win11IconPath: ImageAssets.win11Bill,
                    color: Colors.white,
                    size: 20.spMin,
                  ),
                ),
                SizedBox(width: 6.spMin),
                lgTextBold(text: 'Bills History', color: Colors.white),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.spMin,
                    vertical: 5.spMin,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: smText(
                    text: '$totalBillsCount Total',
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dScafoldColor
                      : Colors.grey.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Container(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dCardColor
                      : Colors.grey.withValues(alpha: 0.05),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          defaultIcon: Icons.check_circle_outline,
                          win11IconPath: ImageAssets.win11Done,
                          size: 16.spMin,
                        ),
                        SizedBox(width: 6.spMin),
                        Flexible(
                          child: smTextBold(
                            text:
                                'Paid (Rs.${completedTotal.toStringAsFixed(0)})',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppIcon(
                          defaultIcon: Icons.pending_outlined,
                          win11IconPath: ImageAssets.win11Pending,
                          size: 16.spMin,
                        ),
                        SizedBox(width: 6.spMin),
                        Flexible(
                          child: smTextBold(
                            text:
                                'Unpaid (Rs.${pendingTotal.toStringAsFixed(0)})',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                labelStyle: TextStyle(
                  fontSize: 13.spMin,
                  fontWeight: FontWeight.bold,
                ),
                labelPadding: EdgeInsets.symmetric(vertical: 4.spMin),
                indicatorSize: TabBarIndicatorSize.tab,
                padding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                unselectedLabelStyle: TextStyle(fontSize: 13.spMin),
                labelColor: AppColors.primary,
                unselectedLabelColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.white70
                        : Colors.black54,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                indicatorPadding: EdgeInsets.zero,
              ),
            ),
          ),

          // TabBarView — height scales with the viewport (with a sensible
          // floor) so the bills list gets room on desktop without a cramped
          // fixed box on smaller windows.
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * 0.6).clamp(
              360.0,
              700.0,
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                completedBills.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            defaultIcon: Icons.receipt_outlined,
                            win11IconPath: ImageAssets.win11Bill,
                            size: 60.spMin,
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          SizedBox(height: 12.spMin),
                          mdText(text: 'No paid bills yet', color: Colors.grey),
                        ],
                      ),
                    )
                    : _buildBillsList(completedBills, false),
                pendingBills.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            defaultIcon: Icons.pending_actions_outlined,
                            win11IconPath: ImageAssets.win11Pending,
                            size: 60.spMin,
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                          SizedBox(height: 12.spMin),
                          mdText(text: 'No pending bills', color: Colors.grey),
                        ],
                      ),
                    )
                    : _buildBillsList(pendingBills, true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = ref.watch(customerDetailsProvider).isEditing;
    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: widget.customer.name,
        context: context,
        actions: [
          PopupMenuButton<String>(
            icon: AppIcon(
              size: 18.spMin,
              imgSize: 24.spMin,
              defaultIcon: Icons.more_vert,
              win11IconPath: ImageAssets.win11MenuVertical,
            ),
            onSelected: (value) async {
              if (value == 'edit') {
                _toggleEditMode();
              } else if (value == 'del') {
                _deleteCustomer();
              } else if (value == 'pdf') {
                await _generateCustomerReportPDF();
              }
            },
            itemBuilder:
                (context) => [
                  _menuItem(
                    icon: isEditing ? Icons.cancel : Icons.edit,
                    win11IconPath:
                        isEditing
                            ? ImageAssets.win11Cancel
                            : ImageAssets.win11EditPencil,
                    text: isEditing ? 'Cancel Edit' : 'Edit Profile',
                    value: 'edit',
                  ),
                  _menuItem(
                    icon: Icons.picture_as_pdf,
                    win11IconPath: ImageAssets.win11Pdf,
                    text: 'Generate PDF Report',
                    value: 'pdf',
                  ),
                  _menuItem(
                    icon: Icons.delete,
                    win11IconPath: ImageAssets.win11RecycleBin,
                    text: 'Delete',
                    value: 'del',
                  ),
                ],
          ),
        ],
      ),
      body: ResponsiveWrapper(
        mobile: _buildMobileView(ref),
        tablet: _buildTabletView(ref),
        desktop: _buildDesktopView(ref),
      ),
    );
  }
}

Widget infoRow(
  BuildContext context,
  String title,
  String val,
  IconData icon, {
  String? win11IconPath,
}) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10.r),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.dScafoldColor
              : AppColors.lBodyColor,
      border: Border.all(
        color: AppColors.primary.withValues(alpha: 0.1),
        width: 1,
      ),
    ),
    padding: EdgeInsets.symmetric(horizontal: 6.spMin, vertical: 8.spMin),
    child: Row(
      children: [
        Container(
          padding: EdgeInsets.all(4.spMin),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: AppIcon(
            defaultIcon: icon,
            win11IconPath: win11IconPath,
            size: 18.spMin,
            imgSize: 26.spMin,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 6.spMin),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              smText(text: title, color: Colors.grey),
              SizedBox(height: 2.spMin),
              smTextBold(text: val),
            ],
          ),
        ),
      ],
    ),
  );
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
          // color: Colors.grey,
          size: 18.spMin,
          defaultIcon: icon,
          win11IconPath: win11IconPath,
        ),
        // Icon(icon, size: 18.spMin),
        SizedBox(width: 12.spMin),
        Text(text, style: TextStyle(fontSize: 14.spMin)),
      ],
    ),
  );
}
