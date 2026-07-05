import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../res/components/text_field_widget.dart';
import '../../../utils/app_sizes.dart';
import '../../../view_models/providers/bills_provider.dart';
import 'package:flutter/services.dart';

import '../../../view_models/states/bills_states.dart';

class FilterRow extends ConsumerStatefulWidget {
  const FilterRow({super.key});

  @override
  FilterRowState createState() => FilterRowState();
}

class FilterRowState extends ConsumerState<FilterRow> {
  late final TextEditingController totalAmountMinController;
  late final TextEditingController totalAmountMaxController;
  late final TextEditingController itemCountMinController;
  late final TextEditingController itemCountMaxController;
  late final TextEditingController dateRangeController;

  @override
  void initState() {
    super.initState();
    final billsState = ref.read(billsProvider);
    totalAmountMinController = TextEditingController(
      text: billsState.totalAmountMin?.toString() ?? '',
    );
    totalAmountMaxController = TextEditingController(
      text: billsState.totalAmountMax?.toString() ?? '',
    );
    itemCountMinController = TextEditingController(
      text: billsState.itemCountMin?.toString() ?? '',
    );
    itemCountMaxController = TextEditingController(
      text: billsState.itemCountMax?.toString() ?? '',
    );
    dateRangeController = TextEditingController(
      text:
          billsState.dateRangeFilter == null
              ? ''
              : '${DateFormat('dd MMM').format(billsState.dateRangeFilter!.start)} - ${DateFormat('dd MMM').format(billsState.dateRangeFilter!.end)}',
    );
  }

  @override
  void dispose() {
    totalAmountMinController.dispose();
    totalAmountMaxController.dispose();
    itemCountMinController.dispose();
    itemCountMaxController.dispose();
    dateRangeController.dispose();
    super.dispose();
  }

  void _updateControllers(BillsState state) {
    totalAmountMinController.text = state.totalAmountMin?.toString() ?? '';
    totalAmountMaxController.text = state.totalAmountMax?.toString() ?? '';
    itemCountMinController.text = state.itemCountMin?.toString() ?? '';
    itemCountMaxController.text = state.itemCountMax?.toString() ?? '';
    dateRangeController.text =
        state.dateRangeFilter == null
            ? ''
            : '${DateFormat('dd MMM').format(state.dateRangeFilter!.start)} - ${DateFormat('dd MMM').format(state.dateRangeFilter!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final billsState = ref.watch(billsProvider);
    final billsNotifier = ref.read(billsProvider.notifier);

    // Listen to state changes to update controllers
    ref.listen(billsProvider, (previous, next) {
      _updateControllers(next);
    });

    // Extract unique payment methods and customers for dropdowns
    final paymentMethods =
        billsState.allBills
            .map((bill) => bill.paymentMethod)
            .where((method) => method != null)
            .toSet()
            .cast<String>()
            .toList();
    final customers =
        billsState.allBills
            .map((bill) => bill.customerName)
            .where((name) => name != null)
            .toSet()
            .cast<String>()
            .toList();

    // Check if any filter is applied
    bool isFilterApplied =
        billsState.statusFilter != null ||
        billsState.paymentMethodFilter != null ||
        billsState.customerFilter != null ||
        billsState.dateRangeFilter != null ||
        billsState.totalAmountMin != null ||
        billsState.totalAmountMax != null ||
        billsState.itemCountMin != null ||
        billsState.itemCountMax != null;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.horizontalPaddingSm.w,
        vertical: AppSizes.verticalPaddingSm - 3.h,
      ),
      child: Column(
        spacing: 6.h,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Header with Clear Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              mdTextBold(text: 'Filters', color: AppColors.primary),
              if (isFilterApplied)
                TextButton.icon(
                  icon: AppIcon(
                    defaultIcon: TablerIcons.x,
                    win11IconPath: ImageAssets.win11Cancel,
                    size: 16.spMin,
                    color: Colors.red,
                  ),
                  label: smTextBold(text: 'Clear', color: Colors.red),
                  onPressed: () {
                    totalAmountMinController.clear();
                    totalAmountMaxController.clear();
                    itemCountMinController.clear();
                    itemCountMaxController.clear();
                    dateRangeController.clear();
                    billsNotifier.clearFilters();
                  },
                ),
            ],
          ),
          SizedBox(height: 8.h),

          // Scrollable Row for Dropdown Filters
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AppDropdown<String?>(
                  label: 'Status',
                  hintText: 'All',
                  value: billsState.statusFilter,
                  items: [null, 'Paid', 'Pending', 'Cancelled'],
                  displayItems: ['All', 'Paid', 'Pending', 'Cancelled'],
                  onChanged: (value) {
                    billsNotifier.setStatusFilter(value);
                  },
                  filled: true,
                  isExpanded: true,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: AppDropdown<String?>(
                  label: 'Payment Method',
                  hintText: 'All',
                  value: billsState.paymentMethodFilter,
                  items: [null, ...paymentMethods],
                  displayItems: ['All', ...paymentMethods],
                  onChanged: (value) {
                    billsNotifier.setPaymentMethodFilter(value);
                  },
                  filled: true,
                  isExpanded: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: AppDropdown<String?>(
                  label: 'Customer',
                  hintText: 'All',
                  value: billsState.customerFilter,
                  items: [null, ...customers],
                  displayItems: ['All', ...customers],
                  onChanged: (value) {
                    billsNotifier.setCustomerFilter(value);
                  },
                  filled: true,
                  isExpanded: true,
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: CustomTextField(
                  label: 'Date Range',
                  hintText: 'Select Date Range',
                  isDense: true,
                  readOnly: true,
                  controller: dateRangeController,
                  suffixIcon: AppIcon(
                    win11IconPath: ImageAssets.win11CalendarPlus,
                    defaultIcon: Icons.calendar_today,
                    size: 18.spMin,
                    color: AppColors.primary,
                  ),
                  filled: true,
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDateRange: billsState.dateRangeFilter,
                    );
                    if (range != null) {
                      billsNotifier.setDateRangeFilter(range);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: CustomTextField(
                        label: 'Min Total',
                        controller: totalAmountMinController,
                        hintText: 'Enter Min Total',
                        keyboardType: TextInputType.number,
                        filled: true,
                        isDense: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = double.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Invalid amount';
                            }
                          }
                          return null;
                        },
                        onChange: (value) {
                          final min = double.tryParse(value ?? '');
                          billsNotifier.setTotalAmountRange(
                            min,
                            double.tryParse(totalAmountMaxController.text),
                          );
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: CustomTextField(
                        label: 'Max Total',
                        controller: totalAmountMaxController,
                        hintText: 'Enter Max Total',
                        keyboardType: TextInputType.number,
                        filled: true,
                        isDense: true,
                        suffixIcon: SizedBox(),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = double.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Invalid amount';
                            }
                            final min = double.tryParse(
                              totalAmountMinController.text,
                            );
                            if (min != null && num < min) {
                              return 'Max < Min';
                            }
                          }
                          return null;
                        },
                        onChange: (value) {
                          final max = double.tryParse(value ?? '');
                          billsNotifier.setTotalAmountRange(
                            double.tryParse(totalAmountMinController.text),
                            max,
                          );
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: CustomTextField(
                        label: 'Min Items',
                        controller: itemCountMinController,
                        hintText: 'Enter Min Items',
                        keyboardType: TextInputType.number,
                        filled: true,
                        isDense: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = int.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Invalid count';
                            }
                          }
                          return null;
                        },
                        onChange: (value) {
                          final min = int.tryParse(value ?? '');
                          billsNotifier.setItemCountRange(
                            min,
                            int.tryParse(itemCountMaxController.text),
                          );
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: CustomTextField(
                        label: 'Max Items',
                        controller: itemCountMaxController,
                        hintText: 'Enter Max Items',
                        keyboardType: TextInputType.number,
                        filled: true,
                        isDense: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final num = int.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Invalid count';
                            }
                            final min = int.tryParse(
                              itemCountMinController.text,
                            );
                            if (min != null && num < min) {
                              return 'Max < Min';
                            }
                          }
                          return null;
                        },
                        onChange: (value) {
                          final max = int.tryParse(value ?? '');
                          billsNotifier.setItemCountRange(
                            int.tryParse(itemCountMinController.text),
                            max,
                          );
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
