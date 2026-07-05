// ignore_for_file: deprecated_member_use

import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import '../../../models/expense_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_button.dart';
import '../../../res/components/app_flushbar.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/text_field_widget.dart';
import '../../../view_models/providers/expense_provider.dart';

class ExpenseDialogs {
  static void showAddExpenseDialog(
    BuildContext context,
    WidgetRef ref,
    List<ExpenseCategory> categories,
  ) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String? selectedCategoryId =
        categories.isNotEmpty ? categories.first.id : null;
    DateTime selectedDate = DateTime.now();
    final double width = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  // insetPadding: EdgeInsets.symmetric(
                  //   horizontal: MediaQuery.of(context).size.width * 0.02,
                  //   vertical: 24,
                  // ),
                  title: SizedBox(
                    width:
                        AppSizes.isMobile(context) ? width * 0.9 : width * 0.6,
                    child: Column(
                      spacing: 10.spMin,
                      children: [
                        Row(
                          children: [
                            AppIcon(
                              win11IconPath: ImageAssets.win11Bill,
                              defaultIcon: TablerIcons.receipt,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 12.spMin),
                            mdTextBold(text: 'Add Expense'),
                          ],
                        ),
                        Divider(),
                      ],
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 20.spMin),
                        CustomTextField(
                          controller: amountController,
                          label: 'Amount',
                          hintText: 'Enter amount',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icon(
                            TablerIcons.currency_dollar,
                            size: 20.spMin,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        AppDropdown(
                          label: 'Category',
                          hintText: 'Select category',
                          items: categories.map((cat) => cat.id).toList(),
                          displayItems:
                              categories.map((cat) => cat.name).toList(),
                          value: selectedCategoryId,
                          onChanged: (value) {
                            setDialogState(() => selectedCategoryId = value);
                          },
                        ),

                        SizedBox(height: 16.h),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            TablerIcons.calendar,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                          ),
                          subtitle: const Text('Tap to change date'),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setDialogState(() => selectedDate = date);
                            }
                          },
                        ),
                        SizedBox(height: 16.h),
                        CustomTextField(
                          controller: noteController,
                          label: 'Note (optional)',
                          hintText: 'Add a note',
                          maxLines: 2,
                          prefixIcon: Icon(TablerIcons.note, size: 20.spMin),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    AppButton().primaryButton(
                      text: 'Add',
                      height: 40.spMin,
                      onPressed: () {
                        final amount = double.tryParse(amountController.text);
                        if (amount == null || amount <= 0) {
                          AppFlushbar.error(
                            context,
                            message: 'Enter a valid amount',
                          );
                          return;
                        }
                        if (selectedCategoryId == null) {
                          AppFlushbar.error(
                            context,
                            message: 'Select a category',
                          );
                          return;
                        }

                        final expense = Expense(
                          amount: amount,
                          categoryId: selectedCategoryId!,
                          date: selectedDate,
                          note:
                              noteController.text.isNotEmpty
                                  ? noteController.text
                                  : null,
                        );

                        ref.read(expenseProvider.notifier).addExpense(expense);
                        Navigator.pop(dialogContext);
                        AppFlushbar.success(context, message: 'Expense added');
                      },
                    ),
                    SizedBox(height: 15.spMin),
                    AppButton().primaryButton(
                      text: 'Cancel',
                      height: 40.spMin,
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
          ),
    );
  }

  static void showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final double width = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(dialogContext).size.width * 0.05,
              vertical: 24,
            ),
            title: SizedBox(
              width: AppSizes.isMobile(context) ? width * 0.9 : width * 0.6,
              child: Row(
                children: [
                  Icon(TablerIcons.category, color: AppColors.primary),
                  SizedBox(width: 8.w),
                  const Text('Add Category'),
                ],
              ),
            ),
            content: CustomTextField(
              controller: nameController,
              label: 'Category Name',
              hintText: 'Enter category name',
              prefixIcon: Icon(TablerIcons.tag, size: 20.spMin),
            ),
            actions: [
              AppButton().primaryButton(
                text: 'Add',
                height: 40.spMin,
                onPressed: () {
                  if (nameController.text.isEmpty) {
                    AppFlushbar.error(
                      context,
                      message: 'Enter a category name',
                    );
                    return;
                  }

                  final category = ExpenseCategory(name: nameController.text);
                  ref.read(expenseProvider.notifier).addCategory(category);
                  Navigator.pop(dialogContext);
                  AppFlushbar.success(context, message: 'Category added');
                },
              ),
              SizedBox(height: 12.spMin),

              AppButton().primaryButton(
                text: 'Cancel',
                height: 40.spMin,
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
    );
  }

  static void showFilterDialog(
    BuildContext context,
    WidgetRef ref,
    ExpenseState state,
  ) {
    String? selectedCategory = state.selectedCategoryFilter;
    DateTime? startDate = state.startDateFilter;
    DateTime? endDate = state.endDateFilter;
    final double width = MediaQuery.sizeOf(context).width;
    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  insetPadding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.05,
                    vertical: 24,
                  ),
                  title: SizedBox(
                    width:
                        AppSizes.isMobile(context) ? width * 0.9 : width * 0.6,
                    child: Row(
                      children: [
                        Icon(TablerIcons.filter, color: AppColors.primary),
                        SizedBox(width: 8.w),
                        const Text('Filter Expenses'),
                      ],
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String?>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...state.categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(cat.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedCategory = value);
                        },
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                startDate != null
                                    ? DateFormat('MMM dd').format(startDate!)
                                    : 'Start Date',
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setDialogState(() => startDate = date);
                                }
                              },
                            ),
                          ),
                          const Text(' - '),
                          Expanded(
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                endDate != null
                                    ? DateFormat('MMM dd').format(endDate!)
                                    : 'End Date',
                              ),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) {
                                  setDialogState(() => endDate = date);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    AppButton().primaryButton(
                      text: 'Apply',
                      height: 40.spMin,
                      onPressed: () {
                        ref
                            .read(expenseProvider.notifier)
                            .setCategoryFilter(selectedCategory);
                        if (startDate != null && endDate != null) {
                          ref
                              .read(expenseProvider.notifier)
                              .setDateFilter(startDate, endDate);
                        }
                        Navigator.pop(dialogContext);
                      },
                    ),
                    SizedBox(height: 12.spMin),

                    AppButton().primaryButton(
                      text: 'Cancel',
                      height: 40.spMin,
                      onPressed: () {
                        ref.read(expenseProvider.notifier).clearFilters();
                        Navigator.pop(dialogContext);
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  static Future<bool> confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final double width = MediaQuery.sizeOf(context).width;

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.05,
              vertical: 24,
            ),
            title: const Text('Delete Expense'),
            content: Text(
              'Delete expense of Rs.${expense.amount.toStringAsFixed(2)}?',
            ),
            actions: [
              AppButton().primaryButton(
                text: 'Delete',
                color: Colors.red,
                height: 40.spMin,
                onPressed: () => Navigator.pop(context, false),
              ),
              SizedBox(height: 12.spMin),
              AppButton().primaryButton(
                text: 'Cancel',
                height: 40.spMin,
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (result == true) {
      await ref.read(expenseProvider.notifier).deleteExpense(expense.id);
      if (context.mounted) {
        AppFlushbar.success(context, message: 'Expense deleted');
      }
      return true;
    }
    return false;
  }
}
