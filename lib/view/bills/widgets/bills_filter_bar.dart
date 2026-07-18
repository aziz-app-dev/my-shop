import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../../res/colors/app_color.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../view_models/providers/bills_provider.dart';

/// Opens the invoices filter popup — status, payment method and date range,
/// with a "Clear all". Styled to match the sales page filter dialog.
void showBillsFilterDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(billsProvider);
          final notifier = ref.read(billsProvider.notifier);

          final methods = state.allBills
              .map((b) => b.paymentMethod)
              .where((m) => m != null && m.trim().isNotEmpty)
              .cast<String>()
              .toSet()
              .toList()
            ..sort();
          final range = state.dateRangeFilter;
          final df = DateFormat('dd MMM');
          final hasAnyFilter = state.statusFilter != null ||
              state.paymentMethodFilter != null ||
              state.dateRangeFilter != null;

          Widget filterChip(String label, bool selected, VoidCallback onTap) {
            return FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 12.spMin,
                  color: selected ? Colors.white : null,
                ),
              ),
              selected: selected,
              selectedColor: AppColors.primary,
              showCheckmark: false,
              side: BorderSide.none,
              onSelected: (_) => onTap(),
            );
          }

          return AlertDialog(
            titlePadding: EdgeInsets.fromLTRB(20.spMin, 16.spMin, 12.spMin, 0),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    mdTextBold(text: 'Filters'),
                    if (hasAnyFilter)
                      TextButton.icon(
                        onPressed: () {
                          notifier.clearFilters();
                          Navigator.pop(dialogContext);
                        },
                        icon: Icon(TablerIcons.filter_off, size: 18.spMin),
                        label: Text(
                          'Clear all',
                          style: TextStyle(fontSize: 12.spMin),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.spMin),
                Divider(height: 1, color: AppColors.grey400),
              ],
            ),
            contentPadding:
                EdgeInsets.fromLTRB(20.spMin, 16.spMin, 20.spMin, 8.spMin),
            content: SizedBox(
              width: 320.spMin,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    mdTextBold(text: 'Status'),
                    SizedBox(height: 8.spMin),
                    Wrap(
                      spacing: 8.spMin,
                      runSpacing: 8.spMin,
                      children: [
                        filterChip('Paid', state.statusFilter == 'Paid',
                            () => notifier.setStatusFilter(
                                state.statusFilter == 'Paid' ? null : 'Paid')),
                        filterChip('Pending', state.statusFilter == 'Pending',
                            () => notifier.setStatusFilter(
                                state.statusFilter == 'Pending'
                                    ? null
                                    : 'Pending')),
                      ],
                    ),
                    if (methods.isNotEmpty) ...[
                      SizedBox(height: 16.spMin),
                      mdTextBold(text: 'Payment Method'),
                      SizedBox(height: 8.spMin),
                      Wrap(
                        spacing: 8.spMin,
                        runSpacing: 8.spMin,
                        children: [
                          for (final m in methods)
                            filterChip(
                              m,
                              state.paymentMethodFilter?.toLowerCase() ==
                                  m.toLowerCase(),
                              () => notifier.setPaymentMethodFilter(
                                state.paymentMethodFilter?.toLowerCase() ==
                                        m.toLowerCase()
                                    ? null
                                    : m,
                              ),
                            ),
                        ],
                      ),
                    ],
                    SizedBox(height: 16.spMin),
                    mdTextBold(text: 'Date Range'),
                    SizedBox(height: 8.spMin),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2015),
                                lastDate: DateTime(2100),
                                initialDateRange: range,
                              );
                              if (picked != null) {
                                notifier.setDateRangeFilter(picked);
                              }
                            },
                            icon: Icon(TablerIcons.calendar, size: 16.spMin),
                            label: Text(
                              range == null
                                  ? 'Any date'
                                  : '${df.format(range.start)} – ${df.format(range.end)}',
                              style: TextStyle(fontSize: 12.spMin),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: range != null
                                    ? AppColors.primary
                                    : AppColors.grey400,
                              ),
                              foregroundColor:
                                  range != null ? AppColors.primary : null,
                            ),
                          ),
                        ),
                        if (range != null)
                          IconButton(
                            tooltip: 'Clear date',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => notifier.setDateRangeFilter(null),
                            icon: Icon(TablerIcons.x,
                                size: 16.spMin, color: AppColors.error),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding:
                EdgeInsets.fromLTRB(20.spMin, 0, 16.spMin, 12.spMin),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Done', style: TextStyle(fontSize: 12.spMin)),
              ),
            ],
          );
        },
      );
    },
  );
}
