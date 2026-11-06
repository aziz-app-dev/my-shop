import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../models/local_purchase_model.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/empty_widget.dart';
import '../../view_models/states/local_purchase_states.dart';
import '../../view_models/services/keyboard/app_keyboard_service.dart';
import '../../utils/app_sizes.dart';
import '../../view_models/providers/local_purchase_provider.dart';
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
  /// Ctrl+N opens the create form — handled by the window-level keyboard
  /// dispatcher (see [AppKeyboardScope]) — focus-independent.
  late final AppKeyboardScope _keys = AppKeyboardScope('purchase-list', (
    event,
  ) {
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyN, ctrl: true)) {
      _openCreateForm();
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
        title: 'Local Purchases',
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
                            'Rs.${agreement.totalAmount.toStringAsFixed(0)}',
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

  Widget _buildDataTable(
    LocalPurchaseState state,
    LocalPurchaseNotifier notifier,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Date')),
          DataColumn(label: Text('Seller')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Items')),
          DataColumn(label: Text('Total'), numeric: true),
          DataColumn(label: Text('Payment')),
          DataColumn(label: Text('Actions')),
        ],
        rows:
            state.filteredAgreements.map((agreement) {
              return DataRow(
                selected: state.selectedAgreements[agreement.id] ?? false,
                onSelectChanged:
                    (selected) =>
                        notifier.toggleSelection(agreement.id, selected),
                cells: [
                  DataCell(
                    Text(DateFormat('dd MMM yyyy').format(agreement.dateTime)),
                  ),
                  DataCell(Text(agreement.sellerName)),
                  DataCell(Text(agreement.sellerPhone ?? '-')),
                  DataCell(Text('${agreement.items.length}')),
                  DataCell(
                    Text('Rs.${agreement.totalAmount.toStringAsFixed(0)}'),
                  ),
                  DataCell(Text(agreement.paymentType)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
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
