import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_bar_widget.dart';
import 'package:desktopapp/res/components/empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../res/assets/image_assets.dart';
import '../../res/components/app_icon.dart';
import '../../view_models/providers/bills_provider.dart';
import 'widgets/data_table_widgets.dart';
import 'widgets/serch_bar_widget.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billsProvider.notifier).fetchBills();
    });
  }

  void _toggleFilterVisibility() {
    ref.read(billsProvider.notifier).toggleFilterVisibility();
  }

  @override
  Widget build(BuildContext context) {
    final billsState = ref.watch(billsProvider);
    final billsNotifier = ref.read(billsProvider.notifier);
    final selectedCount =
        billsState.selectedBills.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: "Invoices",
        context: context,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            splashColor: Colors.transparent,
            icon: AppIcon(
              defaultIcon: Icons.refresh,
              win11IconPath: ImageAssets.win11RotateLeft,
              size: 26.spMin,
            ),
            onPressed: () => billsNotifier.fetchBills(),
            tooltip: 'Refresh',
          ),
          if (selectedCount > 0)
            IconButton(
              icon: AppIcon(
                defaultIcon: Icons.delete,
                win11IconPath: ImageAssets.win11RecycleBin,
                size: 26.spMin,
                color: Colors.redAccent,
              ),
              onPressed: () => billsNotifier.deleteSelectedBills(),
              tooltip: 'Delete Selected',
            ),
        ],
      ),
      body:
          billsState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : billsState.error != null
              ? Center(
                child: Text(
                  'Error: ${billsState.error}',
                  style: TextStyle(fontSize: 16.spMin, color: Colors.red),
                ),
              )
              : billsState.allBills.isEmpty
              ? EmptyWidget1(message: "No Bills found")
              : Column(
                children: [
                  SearchBarWidget(
                    onFilterToggle: _toggleFilterVisibility,
                    isFilterVisible: billsState.isFilterVisible,
                  ),
                  // AnimatedSize(
                  //   duration: const Duration(milliseconds: 300),
                  //   curve: Curves.easeInOut,
                  //   child:
                  //       _isFilterVisible
                  //           ? FilterRow()
                  //           : const SizedBox.shrink(),
                  // ),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.spMin),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${billsState.filteredBills.isNotEmpty ? (billsState.currentPage == (billsState.filteredBills.length / billsState.recordsPerPage).ceil() ? (billsState.filteredBills.length % billsState.recordsPerPage != 0 ? billsState.filteredBills.length % billsState.recordsPerPage : billsState.recordsPerPage) : billsState.recordsPerPage) : 0} of ${billsState.filteredBills.length} bills',
                                style: TextStyle(
                                  fontSize: 12.spMin,
                                  color:
                                      (Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.grey300
                                          : AppColors.grey700),
                                ),
                              ),
                              if ((billsState.filteredBills.length /
                                          billsState.recordsPerPage)
                                      .ceil() >
                                  1)
                                Row(
                                  children: [
                                    IconButton(
                                      icon: AppIcon(
                                        defaultIcon: Icons.arrow_back_ios,
                                        win11IconPath: ImageAssets.win11Back,
                                        size: 20.spMin,
                                      ),
                                      onPressed:
                                          billsState.currentPage > 1
                                              ? () =>
                                                  billsNotifier.setCurrentPage(
                                                    billsState.currentPage - 1,
                                                  )
                                              : null,
                                    ),
                                    Text(
                                      'Page ${billsState.currentPage} of ${(billsState.filteredBills.length / billsState.recordsPerPage).ceil()}',
                                      style: TextStyle(fontSize: 14.spMin),
                                    ),
                                    IconButton(
                                      icon: AppIcon(
                                        defaultIcon: Icons.arrow_forward_ios,
                                        win11IconPath: ImageAssets.win11Forward,
                                        size: 20.spMin,
                                      ),
                                      onPressed:
                                          billsState.currentPage <
                                                  (billsState
                                                              .filteredBills
                                                              .length /
                                                          billsState
                                                              .recordsPerPage)
                                                      .ceil()
                                              ? () =>
                                                  billsNotifier.setCurrentPage(
                                                    billsState.currentPage + 1,
                                                  )
                                              : null,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Expanded(child: DataTableWidget()),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
