import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../res/assets/image_assets.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../res/components/empty_widget.dart';
import '../../res/components/text_field_widget.dart';
import '../../view_models/providers/customer_prvider.dart';
import '../../view_models/states/customer_states.dart';
import '../bills/widgets/data_table_widgets.dart';
import '../home/rapper.dart';
import 'customers_details_view.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 750;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 750 &&
      MediaQuery.of(context).size.width < 1100;

  Widget _buildMobileView(
    CustomersState state,
    WidgetRef ref,
    BuildContext context,
  ) {
    final customers = state.filteredCustomers;
    final startIndex = (state.currentPage - 1) * state.recordsPerPage;
    final endIndex =
        (startIndex + state.recordsPerPage) > customers.length
            ? customers.length
            : (startIndex + state.recordsPerPage);
    final paginatedCustomers =
        customers.isNotEmpty ? customers.sublist(startIndex, endIndex) : [];

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.spMin),
          child: CustomTextField(
            hintText: 'Search customers...',
            isSearch: true,
            prefixIcon: AppIcon(
              defaultIcon: Icons.search,
              win11IconPath: ImageAssets.win11Search,
              size: 16.spMin,
            ),
            onChange: (value) {
              ref.read(customersProvider.notifier).searchCustomers(value ?? '');
              return null;
            },
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: 8.spMin,
              vertical: 4.spMin,
            ),
            itemCount: paginatedCustomers.length,
            itemBuilder: (context, index) {
              final customer = paginatedCustomers[index];
              final isSelected = state.selectedCustomers[customer.id] ?? false;
              final pendingAmount = state.pendingAmounts[customer.id] ?? 0.0;
              final completedCount =
                  state.completedBillCounts[customer.id] ?? 0;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
                color:
                    isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : null,
                child: InkWell(
                  hoverColor: Colors.transparent,
                  onTap: () {
                    if (state.isSelectionMode) {
                      ref
                          .read(customersProvider.notifier)
                          .toggleCustomerSelection(customer.id, !isSelected);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  CustomerDetailsScreen(customer: customer),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    ref
                        .read(customersProvider.notifier)
                        .toggleCustomerSelection(customer.id, true);
                  },
                  child: Padding(
                    padding: EdgeInsets.all(8.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                  defaultIcon: Icons.person,
                                  win11IconPath: ImageAssets.win11TestAccount,
                                  size: 14.spMin,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.dIconColor
                                          : AppColors.primary,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: mdTextBold(text: customer.name),
                                ),
                              ],
                            ),
                            smText(
                              text: 'Visits: ${customer.visitCount}',
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                  defaultIcon: Icons.phone,
                                  win11IconPath: ImageAssets.win11Phone,
                                  size: 14.spMin,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.dIconColor
                                          : AppColors.primary,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: xsText(
                                    text:
                                        customer.phoneNumber.isEmpty
                                            ? 'N/A'
                                            : customer.phoneNumber,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (pendingAmount > 0) ...[
                                  AppIcon(
                                    defaultIcon: TablerIcons.parking_circle,
                                    win11IconPath: ImageAssets.win11Pending,
                                    size: 14.spMin,
                                    color: Colors.orange,
                                  ),
                                  SizedBox(width: 4.w),
                                  xsText(
                                    text:
                                        'Pending: ${state.pendingBillCounts[customer.id] ?? 0} (Rs ${pendingAmount.toStringAsFixed(2)})',
                                    color: Colors.orange,
                                  ),
                                ] else if (completedCount > 0) ...[
                                  AppIcon(
                                    defaultIcon: Icons.check_circle,
                                    win11IconPath: ImageAssets.win11Done,
                                    size: 14.spMin,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 4.w),
                                  xsText(
                                    text: 'Completed: $completedCount',
                                    color: Colors.green,
                                  ),
                                ] else ...[
                                  xsText(text: 'No Bills'),
                                ],
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon(
                                  defaultIcon: Icons.location_on,
                                  win11IconPath: ImageAssets.win11Location,
                                  size: 14.spMin,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.dIconColor
                                          : AppColors.primary,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: xsText(
                                    text:
                                        customer.address.isEmpty
                                            ? 'N/A'
                                            : customer.address,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (state.isSelectionMode && isSelected)
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
          ),
        ),
        if (customers.length > state.recordsPerPage)
          _buildPaginationControls(state, ref, context),
      ],
    );
  }

  Widget _buildTableView(
    CustomersState state,
    WidgetRef ref,
    BuildContext context,
  ) {
    final customers = state.filteredCustomers;
    final startIndex = (state.currentPage - 1) * state.recordsPerPage;
    final endIndex =
        (startIndex + state.recordsPerPage) > customers.length
            ? customers.length
            : (startIndex + state.recordsPerPage);
    final paginatedCustomers =
        customers.isNotEmpty ? customers.sublist(startIndex, endIndex) : [];

    if (paginatedCustomers.isEmpty) {
      return Center(child: mdText(text: 'No customers found'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.spMin,
            vertical: 16.spMin,
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 18.spMin),
                child: CustomTextField(
                  hintText: 'Search customers...',
                  isSearch: true,
                  prefixIcon: AppIcon(
                    defaultIcon: Icons.search,
                    win11IconPath: ImageAssets.win11Search,
                    size: 16.spMin,
                  ),
                  onChange: (value) {
                    ref
                        .read(customersProvider.notifier)
                        .searchCustomers(value ?? '');
                    return null;
                  },
                ),
              ),
              Expanded(
                child: DataTable2(
                  dividerThickness: 0,
                  showCheckboxColumn: state.isSelectionMode,
                  headingCheckboxTheme: CheckboxThemeData(
                    fillColor: WidgetStateProperty.resolveWith(
                      (states) =>
                          states.contains(WidgetState.selected)
                              ? AppColors.primary
                              : Colors.transparent,
                    ),
                    checkColor: WidgetStateProperty.all(Colors.white),
                    side: BorderSide(color: Colors.white, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
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
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  columnSpacing: 0.5.spMin, // Reduced column spacing
                  horizontalMargin: 0,
                  minWidth: constraints.maxWidth,
                  headingRowHeight: 40.spMin,
                  dataRowHeight: 40.spMin,
                  headingRowDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: AppColors.primaryLight2,
                  ),
                  dataTextStyle: TextStyle(fontSize: 12.spMin),
                  columns: [
                    DataColumn2(
                      label: DataTableHeaderCell(
                        win11Icon: ImageAssets.win11TestAccount,

                        icon: Icons.person,
                        title: 'Name',
                      ),
                      size: ColumnSize.S,
                      onSort:
                          (i, a) => ref
                              .read(customersProvider.notifier)
                              .sortCustomers(i, a),
                    ),
                    DataColumn2(
                      label: DataTableHeaderCell(
                        win11Icon: ImageAssets.win11Phone,

                        icon: Icons.phone,
                        title: 'Phone',
                      ),
                      size: ColumnSize.S,
                      onSort:
                          (i, a) => ref
                              .read(customersProvider.notifier)
                              .sortCustomers(i, a),
                    ),
                    DataColumn2(
                      label: DataTableHeaderCell(
                        win11Icon: ImageAssets.win11Location,
                        icon: Icons.location_on,
                        title: 'Address',
                      ),
                      size: ColumnSize.S,
                      onSort:
                          (i, a) => ref
                              .read(customersProvider.notifier)
                              .sortCustomers(i, a),
                    ),
                    DataColumn2(
                      label: DataTableHeaderCell(
                        win11Icon: ImageAssets.win11DeliveryTime,
                        icon: TablerIcons.clock,
                        title: 'Visits',
                      ),
                      size: ColumnSize.S,
                      numeric: true,
                      onSort:
                          (i, a) => ref
                              .read(customersProvider.notifier)
                              .sortCustomers(i, a),
                    ),
                    DataColumn2(
                      label: DataTableHeaderCell(
                        win11Icon: ImageAssets.win11Done,
                        icon: TablerIcons.parking_circle,
                        title: 'Bill Status',
                      ),
                      size: ColumnSize.S,
                      onSort:
                          (i, a) => ref
                              .read(customersProvider.notifier)
                              .sortCustomers(i, a),
                    ),
                  ],
                  rows:
                      paginatedCustomers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final customer = entry.value;
                        final isSelected =
                            state.selectedCustomers[customer.id] ?? false;
                        final pendingAmount =
                            state.pendingAmounts[customer.id] ?? 0.0;
                        final completedCount =
                            state.completedBillCounts[customer.id] ?? 0;

                        return DataRow2(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color:
                                index.isEven
                                    ? Colors.transparent
                                    : Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? AppColors.grey800
                                    : AppColors.primary.withValues(alpha: 0.1),
                          ),
                          selected: isSelected,
                          onSelectChanged:
                              state.isSelectionMode
                                  ? (value) => ref
                                      .read(customersProvider.notifier)
                                      .toggleCustomerSelection(
                                        customer.id,
                                        value,
                                      )
                                  : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CustomerDetailsScreen(
                                      customer: customer,
                                    ),
                              ),
                            );
                          },
                          cells: [
                            DataCell(
                              TableDataCellText(
                                text: customer.name,
                                tooltip: true,
                              ),
                            ),
                            DataCell(
                              TableDataCellText(
                                text:
                                    customer.phoneNumber.isEmpty
                                        ? 'N/A'
                                        : customer.phoneNumber,
                                tooltip: true,
                              ),
                            ),
                            DataCell(
                              TableDataCellText(
                                text:
                                    customer.address.isEmpty
                                        ? 'N/A'
                                        : customer.address,
                                tooltip: true,
                              ),
                            ),
                            DataCell(
                              TableDataCellText(text: '${customer.visitCount}'),
                            ),
                            DataCell(
                              pendingAmount > 0
                                  ? TableDataCellText(
                                    text:
                                        'Pending: ${state.pendingBillCounts[customer.id] ?? 0} (Rs ${pendingAmount.toStringAsFixed(2)})',
                                    color: Colors.orange,
                                  )
                                  : completedCount > 0
                                  ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppIcon(
                                        defaultIcon: Icons.check_circle,
                                        win11IconPath: ImageAssets.win11Done,
                                        size: 14.spMin,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 4.w),
                                      TableDataCellText(
                                        text: 'Completed: $completedCount',
                                        color: Colors.green,
                                      ),
                                    ],
                                  )
                                  : TableDataCellText(text: 'No Bills'),
                            ),
                          ],
                        );
                      }).toList(),
                  sortColumnIndex: state.sortColumnIndex,
                  sortAscending: state.sortAscending,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
              if (customers.length > state.recordsPerPage)
                _buildPaginationControls(state, ref, context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls(
    CustomersState state,
    WidgetRef ref,
    BuildContext context,
  ) {
    final totalPages =
        (state.filteredCustomers.length / state.recordsPerPage).ceil();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: AppIcon(
              defaultIcon: Icons.arrow_back_ios,
              win11IconPath: ImageAssets.win11Back,
              size: 16.spMin,
            ),
            onPressed:
                state.currentPage > 1
                    ? () => ref
                        .read(customersProvider.notifier)
                        .setPage(state.currentPage - 1)
                    : null,
          ),
          Text(
            'Page ${state.currentPage} of $totalPages',
            style: TextStyle(fontSize: 12.spMin),
          ),
          IconButton(
            icon: AppIcon(
              defaultIcon: Icons.arrow_forward_ios,
              win11IconPath: ImageAssets.win11Forward,
              size: 16.spMin,
            ),
            onPressed:
                state.currentPage < totalPages
                    ? () => ref
                        .read(customersProvider.notifier)
                        .setPage(state.currentPage + 1)
                    : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersState = ref.watch(customersProvider);

    // Show loading indicator only when actually loading
    if (customersState.isLoading) {
      return Scaffold(
        appBar: AppBarWidget.customAppBar(
          title: 'Customers',
          context: context,
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show error state
    if (customersState.error != null) {
      return Scaffold(
        appBar: AppBarWidget.customAppBar(
          title: 'Customers',
          context: context,
          automaticallyImplyLeading: false,
        ),
        body: Center(child: mdText(text: 'Error: ${customersState.error}')),
      );
    }

    // Show empty state when no customers exist
    if (customersState.allCustomers.isEmpty) {
      return Scaffold(
        appBar: AppBarWidget.customAppBar(
          title: 'Customers',
          context: context,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: AppIcon(
                defaultIcon: Icons.refresh,
                win11IconPath: ImageAssets.win11RotateLeft,
                size: 20.spMin,
              ),
              onPressed: () => ref.read(customersProvider.notifier).refresh(),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: EmptyWidget1(message: "No customer found"),
      );
    }

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Customers',
        automaticallyImplyLeading: false,
        context: context,
        actions: [
          IconButton(
            icon: AppIcon(
              defaultIcon: Icons.refresh,
              win11IconPath: ImageAssets.win11RotateLeft,
              size: 20.spMin,
            ),
            onPressed: () => ref.read(customersProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ResponsiveWrapper(
              mobile: _buildMobileView(customersState, ref, context),
              tablet: _buildTableView(customersState, ref, context),
              desktop: _buildTableView(customersState, ref, context),
            ),
          ),
        ],
      ),
    );
  }
}
