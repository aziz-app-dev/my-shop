import '../../utils/currency_service.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../models/local_purchase_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/empty_widget.dart';
import '../../view_models/states/local_purchase_states.dart';
import '../../view_models/services/keyboard/app_keyboard_service.dart';
import '../../utils/app_sizes.dart';
import '../../view_models/providers/local_purchase_provider.dart';
import '../bills/widgets/data_table_widgets.dart'
    show DataTableHeaderCell, TableDataCellText;
import 'local_purchase_detail_view.dart';
import 'local_purchase_form_view.dart';

class LocalPurchaseListView extends ConsumerStatefulWidget {
  final VoidCallback? openDrawer;

  const LocalPurchaseListView({super.key, this.openDrawer});

  @override
  ConsumerState<LocalPurchaseListView> createState() =>
      _LocalPurchaseListViewState();
}

class _LocalPurchaseListViewState extends ConsumerState<LocalPurchaseListView> {
  /// Window-level shortcuts:
  ///  * Ctrl+N opens the create form.
  ///  * Ctrl+P prints the single selected purchase (same PDF pipeline as the
  ///    detail screen, via [LocalPurchaseDetailView] with autoPrint).
  late final AppKeyboardScope _keys = AppKeyboardScope('purchase-list', (
    event,
  ) {
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyN, ctrl: true)) {
      _openCreateForm();
      return true;
    }
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyP, ctrl: true)) {
      _printSelectedAgreement();
      return true;
    }
    return false;
  });

  @override
  void initState() {
    super.initState();
    AppKeyboardScope.register(_keys);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localPurchaseProvider.notifier).fetchAgreements();
    });
  }

  @override
  void dispose() {
    AppKeyboardScope.unregister(_keys);
    super.dispose();
  }

  void _openCreateForm() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocalPurchaseFormView()),
    );
  }

  void _openDetail(LocalPurchaseAgreement agreement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LocalPurchaseDetailView(agreement: agreement),
      ),
    );
  }

  /// Prints the single selected purchase. If none or several are selected,
  /// it guides the user instead of failing silently — same behavior as the
  /// bills list's Ctrl+P. The print itself is delegated to
  /// [LocalPurchaseDetailView] (autoPrint) so the list reuses the exact
  /// same PDF pipeline as the detail screen.
  void _printSelectedAgreement() {
    final state = ref.read(localPurchaseProvider);
    final selected =
        state.allAgreements
            .where((a) => state.selectedAgreements[a.id] == true)
            .toList();

    if (selected.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => LocalPurchaseDetailView(
                agreement: selected.first,
                autoPrint: true,
              ),
        ),
      );
    } else if (selected.isEmpty) {
      AppFlushbar.info(
        context,
        message: 'Select a purchase, then press Ctrl+P to print it.',
      );
    } else {
      AppFlushbar.info(
        context,
        message: 'Select a single purchase to print with Ctrl+P.',
      );
    }
  }

  void _confirmDeleteSelected() {
    final notifier = ref.read(localPurchaseProvider.notifier);
    final count = ref.read(localPurchaseProvider).selectedCount;
    if (count == 0) return;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Agreements'),
            content: Text('Delete $count selected agreement(s)?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await notifier.deleteSelected();
                  if (mounted) {
                    AppFlushbar.success(
                      context,
                      message: '$count agreement(s) deleted.',
                    );
                  }
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localPurchaseProvider);
    final notifier = ref.read(localPurchaseProvider.notifier);
    final isMobile = AppSizes.isMobile(context);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Purchase',
        context: context,
        automaticallyImplyLeading: isMobile,
        backIcon: isMobile ? Icons.menu : null,
        leadingOnTap: isMobile ? widget.openDrawer : null,
        actions: [
          if (state.isSelectionMode) ...[
            TextButton.icon(
              onPressed: _confirmDeleteSelected,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: Text(
                'Delete (${state.selectedCount})',
                style: const TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: notifier.clearSelections,
              child: const Text('Cancel'),
            ),
          ] else ...[
            // Desktop uses Ctrl+N (search box focused most of the time, so a
            // visible tap target is only needed on mobile).
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New Agreement (Ctrl+N)',
                onPressed: _openCreateForm,
              ),
          ],
        ],
      ),
      body: _buildBody(state, notifier),
    );
  }

  Widget _buildBody(LocalPurchaseState state, LocalPurchaseNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}'),
            TextButton(
              onPressed: notifier.fetchAgreements,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchBar(notifier),
        Expanded(
          child:
              state.filteredAgreements.isEmpty
                  ? const EmptyWidget1(message: 'No purchase agreements found')
                  : _buildList(state, notifier),
        ),
      ],
    );
  }

  Widget _buildSearchBar(LocalPurchaseNotifier notifier) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: TextField(
        controller: notifier.searchController,
        // Desktop: navigation lands here with the keyboard ready in the
        // search box.
        autofocus: AppSizes.isDesktop(context),
        decoration: InputDecoration(
          hintText: 'Search by seller name, phone, ID card...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              notifier.searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: notifier.searchController.clear,
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }

  Widget _buildList(LocalPurchaseState state, LocalPurchaseNotifier notifier) {
    final isDesktop = AppSizes.isDesktop(context);

    if (isDesktop) {
      return _buildDataTable(state, notifier);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      itemCount: state.filteredAgreements.length,
      itemBuilder: (context, index) {
        final agreement = state.filteredAgreements[index];
        return _buildCard(agreement, state, notifier);
      },
    );
  }

  Widget _buildCard(
    LocalPurchaseAgreement agreement,
    LocalPurchaseState state,
    LocalPurchaseNotifier notifier,
  ) {
    final isSelected = state.selectedAgreements[agreement.id] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: () {
          if (state.isSelectionMode) {
            notifier.toggleSelection(agreement.id, !isSelected);
          } else {
            _openDetail(agreement);
          }
        },
        onLongPress: () {
          notifier.setSelectionMode(true);
          notifier.toggleSelection(agreement.id, true);
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.spMin),
          child: Row(
            children: [
              if (state.isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (v) => notifier.toggleSelection(agreement.id, v),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            agreement.sellerName,
                            style: TextStyle(
                              fontSize: 14.spMin,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${CurrencyService.symbol}${agreement.totalAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12.spMin,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12.spMin,
                          color: Colors.grey,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          DateFormat('dd MMM yyyy').format(agreement.dateTime),
                          style: TextStyle(
                            fontSize: 11.spMin,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.payment, size: 12.spMin, color: Colors.grey),
                        SizedBox(width: 4.w),
                        Text(
                          agreement.paymentType,
                          style: TextStyle(
                            fontSize: 11.spMin,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (agreement.sellerPhone != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Phone: ${agreement.sellerPhone}',
                        style: TextStyle(
                          fontSize: 11.spMin,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Desktop table — the SAME styled [DataTable2] used by the Invoices
  /// (bills) and Customers pages: shared header cells, striped rows,
  /// selection checkboxes and the primary heading band.
  Widget _buildDataTable(
    LocalPurchaseState state,
    LocalPurchaseNotifier notifier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.spMin,
            vertical: 16.spMin,
          ),
          child: DataTable2(
            dividerThickness: 0,
            showCheckboxColumn: true,
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
            columnSpacing: 0.5.spMin,
            // Leading/trailing gap so the selection checkboxes don't touch
            // the screen edge — same as the Invoices table.
            horizontalMargin: 4.w,
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
                  win11Icon: ImageAssets.win11DeliveryTime,
                  icon: Icons.calendar_today,
                  title: 'Date',
                ),
                size: ColumnSize.S,
              ),
              DataColumn2(
                label: DataTableHeaderCell(
                  win11Icon: ImageAssets.win11TestAccount,
                  icon: Icons.person,
                  title: 'Seller',
                ),
                size: ColumnSize.L,
              ),
              DataColumn2(
                label: DataTableHeaderCell(
                  win11Icon: ImageAssets.win11Phone,
                  icon: Icons.phone,
                  title: 'Phone',
                ),
                size: ColumnSize.M,
              ),
              DataColumn2(
                label: DataTableHeaderCell(
                  win11Icon: ImageAssets.win11Stock,
                  icon: Icons.inventory_2_outlined,
                  title: 'Items',
                ),
                size: ColumnSize.S,
                numeric: true,
              ),
              DataColumn2(
                label: DataTableHeaderCell(
                  win11Icon: ImageAssets.win11Cash,
                  icon: Icons.payments_outlined,
                  title: 'Total',
                ),
                size: ColumnSize.M,
                numeric: true,
              ),
              DataColumn2(
                label: DataTableHeaderCell(
                  win11Icon: ImageAssets.win11Card,
                  icon: Icons.payment,
                  title: 'Payment',
                ),
                size: ColumnSize.M,
              ),
              DataColumn2(
                label: DataTableHeaderCell(
                  win11Icon: ImageAssets.win11CircledMenu,
                  icon: Icons.more_horiz,
                  title: 'Actions',
                ),
                size: ColumnSize.S,
              ),
            ],
            rows:
                state.filteredAgreements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final agreement = entry.value;
                  final isSelected =
                      state.selectedAgreements[agreement.id] ?? false;

                  return DataRow2(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color:
                          index.isEven
                              ? Colors.transparent
                              : Theme.of(context).brightness == Brightness.dark
                              ? AppColors.grey800
                              : AppColors.primary.withValues(alpha: 0.1),
                    ),
                    selected: isSelected,
                    onSelectChanged:
                        (selected) =>
                            notifier.toggleSelection(agreement.id, selected),
                    onTap: () => _openDetail(agreement),
                    cells: [
                      DataCell(
                        TableDataCellText(
                          text: DateFormat(
                            'dd MMM yyyy',
                          ).format(agreement.dateTime),
                        ),
                      ),
                      DataCell(
                        TableDataCellText(
                          text: agreement.sellerName,
                          tooltip: true,
                        ),
                      ),
                      DataCell(
                        TableDataCellText(
                          text: agreement.sellerPhone ?? 'N/A',
                          tooltip: true,
                        ),
                      ),
                      DataCell(
                        TableDataCellText(text: '${agreement.items.length}'),
                      ),
                      DataCell(
                        TableDataCellText(
                          text:
                              '${CurrencyService.symbol}${agreement.totalAmount.toStringAsFixed(0)}',
                          color: AppColors.primary,
                        ),
                      ),
                      DataCell(
                        TableDataCellText(
                          text: agreement.paymentType,
                          tooltip: true,
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, size: 18),
                              onPressed: () => _openDetail(agreement),
                              tooltip: 'View',
                            ),
                            IconButton(
                              icon: const Icon(Icons.print, size: 18),
                              onPressed: () => _printAgreement(agreement),
                              tooltip: 'Print',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
          ),
        );
      },
    );
  }

  void _printAgreement(LocalPurchaseAgreement agreement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                LocalPurchaseDetailView(agreement: agreement, autoPrint: true),
      ),
    );
  }
}
