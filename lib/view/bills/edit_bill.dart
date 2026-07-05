// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../models/bills_model.dart';
import '../../models/coustomer_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../res/components/text_field_widget.dart';
import '../../utils/payment_calculator.dart';
import '../../view_models/providers/bills_provider.dart';
import '../../view_models/providers/sales_provider.dart';
import '../../view_models/providers/edit_bill_provider.dart';
import '../home/rapper.dart';
import '../sales/check_out_view.dart';
import '../../res/components/app_button.dart';

class EditBillScreen extends ConsumerStatefulWidget {
  final Bill bill;

  const EditBillScreen({super.key, required this.bill});

  @override
  EditBillScreenState createState() => EditBillScreenState();
}

class EditBillScreenState extends ConsumerState<EditBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController paidAmountController;
  late TextEditingController discountController;
  late TextEditingController statusController;
  late TextEditingController paymentMethodController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with bill data
    nameController = TextEditingController(
      text: widget.bill.customerName ?? '',
    );
    addressController = TextEditingController(text: '');
    phoneController = TextEditingController(text: '');
    paidAmountController = TextEditingController(
      text: widget.bill.paidAmount.toStringAsFixed(0),
    );
    discountController = TextEditingController(
      text: widget.bill.discount.toStringAsFixed(0),
    );
    statusController = TextEditingController(text: widget.bill.status);
    paymentMethodController = TextEditingController(
      text: widget.bill.paymentMethod ?? '',
    );

    // Load customers and update address and phone controllers
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(editBillProvider(widget.bill).notifier).loadCustomers();
      final editState = ref.read(editBillProvider(widget.bill));

      if (widget.bill.customerId != null) {
        final customer = editState.fullCustomers.firstWhere(
          (c) => c.id == widget.bill.customerId,
          orElse:
              () => Customer(id: '', name: '', address: '', phoneNumber: ''),
        );
        addressController.text = customer.address;
        phoneController.text = customer.phoneNumber;
      }

      // Update field configurations
      final fieldConfigs =
          await ref.read(databaseServiceProvider).getCustomerFieldConfigs();
      ref
          .read(customerFormProvider.notifier)
          .updateFieldConfig(
            'name',
            title: fieldConfigs['name']?.title ?? 'Customer Name',
            hintText: fieldConfigs['name']?.hintText ?? 'Enter customer name',
            validatorText:
                fieldConfigs['name']?.validatorText ??
                'Customer name is required',
            isShow: fieldConfigs['name']?.isShow ?? true,
            isRequired: fieldConfigs['name']?.isRequired ?? true,
          );
      ref
          .read(customerFormProvider.notifier)
          .updateFieldConfig(
            'address',
            title: fieldConfigs['address']?.title ?? 'Address',
            hintText: fieldConfigs['address']?.hintText ?? 'Enter address',
            validatorText:
                fieldConfigs['address']?.validatorText ?? 'Address is required',
            isShow: fieldConfigs['address']?.isShow ?? true,
            isRequired: fieldConfigs['address']?.isRequired ?? false,
          );
      ref
          .read(customerFormProvider.notifier)
          .updateFieldConfig(
            'phoneNumber',
            title: fieldConfigs['phoneNumber']?.title ?? 'Phone Number',
            hintText:
                fieldConfigs['phoneNumber']?.hintText ?? 'Enter phone number',
            validatorText:
                fieldConfigs['phoneNumber']?.validatorText ??
                'Phone number is required',
            isShow: fieldConfigs['phoneNumber']?.isShow ?? true,
            isRequired: fieldConfigs['phoneNumber']?.isRequired ?? false,
          );
      ref
          .read(customerFormProvider.notifier)
          .updateFieldConfig(
            'paidAmount',
            title: fieldConfigs['paidAmount']?.title ?? 'Paid Amount',
            hintText:
                fieldConfigs['paidAmount']?.hintText ?? 'Enter paid amount',
            validatorText:
                fieldConfigs['paidAmount']?.validatorText ?? 'Invalid amount',
            isShow: fieldConfigs['paidAmount']?.isShow ?? true,
            isRequired: fieldConfigs['paidAmount']?.isRequired ?? false,
          );
      ref
          .read(customerFormProvider.notifier)
          .updateFieldConfig(
            'paymentStatus',
            title: fieldConfigs['paymentStatus']?.title ?? 'Payment Status',
            hintText:
                fieldConfigs['paymentStatus']?.hintText ??
                'Select payment status',
            validatorText:
                fieldConfigs['paymentStatus']?.validatorText ??
                'Payment status is required',
            isShow: fieldConfigs['paymentStatus']?.isShow ?? true,
            isRequired: fieldConfigs['paymentStatus']?.isRequired ?? true,
          );
      ref
          .read(customerFormProvider.notifier)
          .updateFieldConfig(
            'paymentMethod',
            title: fieldConfigs['paymentMethod']?.title ?? 'Payment Method',
            hintText:
                fieldConfigs['paymentMethod']?.hintText ??
                'Select payment method',
            validatorText:
                fieldConfigs['paymentMethod']?.validatorText ??
                'Payment method is required',
            isShow: fieldConfigs['paymentMethod']?.isShow ?? true,
            isRequired: fieldConfigs['paymentMethod']?.isRequired ?? true,
          );
      ref
          .read(customerFormProvider.notifier)
          .updateFieldConfig(
            'discount',
            title: fieldConfigs['discount']?.title ?? 'Discount',
            hintText:
                fieldConfigs['discount']?.hintText ?? 'Enter discount amount',
            validatorText:
                fieldConfigs['discount']?.validatorText ??
                'Invalid discount amount',
            isShow: fieldConfigs['discount']?.isShow ?? true,
            isRequired: fieldConfigs['discount']?.isRequired ?? false,
          );
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    paidAmountController.dispose();
    discountController.dispose();
    statusController.dispose();
    paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _updateBill() async {
    if (_formKey.currentState!.validate()) {
      final editState = ref.read(editBillProvider(widget.bill));
      final updatedItems = editState.updatedItems;
      final updatedQuantities = editState.updatedQuantities;

      final totalAmount = updatedItems.fold<double>(
        0.0,
        (sum, item) => sum + item.price * (updatedQuantities[item.id] ?? 1),
      );
      final discount = double.tryParse(discountController.text) ?? 0.0;
      final paidAmount = double.tryParse(paidAmountController.text) ?? 0.0;

      // Validate payment using PaymentCalculator
      final validation = PaymentCalculator.validatePayment(
        totalAmount: totalAmount,
        discount: discount,
        paidAmount: paidAmount,
      );

      if (!validation.isValid) {
        AppFlushbar.error(
          context,
          message: validation.errorMessage ?? 'Invalid payment',
        );
        return;
      }

      // Use PaymentCalculator for consistent status determination
      final billStatus = PaymentCalculator.calculatePaymentStatus(
        totalAmount: totalAmount,
        discount: discount,
        paidAmount: paidAmount,
      );

      final updatedBill = widget.bill.copyWith(
        customerName: nameController.text.isEmpty ? null : nameController.text,
        customerId:
            editState.fullCustomers
                .firstWhere(
                  (c) => c.name == nameController.text,
                  orElse:
                      () => Customer(
                        id: '',
                        name: nameController.text,
                        address: '',
                        phoneNumber: '',
                      ),
                )
                .id,
        status: billStatus,
        paymentMethod:
            paymentMethodController.text.isEmpty
                ? null
                : paymentMethodController.text,
        discount: discount,
        paidAmount: paidAmount,
        totalAmount: totalAmount,
        items: updatedItems,
        quantities: updatedQuantities,
      );

      await ref.read(databaseServiceProvider).saveBill(updatedBill);
      ref.read(billsProvider.notifier).fetchBills();
      Navigator.pop(context);
    }
  }

  Widget _buildNameField(CustomerFormState customerFormState) {
    return CustomTextField(
      controller: nameController,
      hintText: customerFormState.fieldConfigs['name']!.hintText,
      label: customerFormState.fieldConfigs['name']!.title,
      keyboardType: TextInputType.name,
      filled: true,
      prefixIcon: AppIcon(
        defaultIcon: Icons.person,
        win11IconPath: ImageAssets.win11People,
        size: 20.spMin,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lIconColor,
      ),
      validator: (value) {
        if (customerFormState.fieldConfigs['name']!.isRequired &&
            (value == null || value.isEmpty)) {
          return customerFormState.fieldConfigs['name']!.validatorText;
        }
        return null;
      },
      onChange: (value) {
        ref.read(customerFormProvider.notifier).updateName(value ?? '');
        ref
            .read(editBillProvider(widget.bill).notifier)
            .filterCustomers(value ?? '');
        return null;
      },
    );
  }

  Widget _buildSuggestions() {
    final editState = ref.watch(editBillProvider(widget.bill));
    return editState.showSuggestions && editState.filteredCustomers.isNotEmpty
        ? Padding(
          padding: EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8.r)),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 150.h),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: editState.filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = editState.filteredCustomers[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AppIcon(
                            defaultIcon: Icons.person,
                            win11IconPath: ImageAssets.win11People,
                            size: 14.spMin,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          smText(
                            text: customer.name,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                        ],
                      ),
                      subtitle: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AppIcon(
                                defaultIcon: Icons.location_city,
                                win11IconPath: ImageAssets.win11Location,
                                size: 14.spMin,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              smText(
                                text: customer.address,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AppIcon(
                                defaultIcon: Icons.phone,
                                win11IconPath: ImageAssets.win11Phone,
                                size: 14.spMin,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              smText(
                                text: customer.phoneNumber,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        nameController.text = customer.name;
                        addressController.text = customer.address;
                        phoneController.text = customer.phoneNumber;
                        ref
                            .read(editBillProvider(widget.bill).notifier)
                            .hideSuggestions();
                        ref
                            .read(customerFormProvider.notifier)
                            .updateName(customer.name);
                        ref
                            .read(customerFormProvider.notifier)
                            .updateAddress(customer.address);
                        ref
                            .read(customerFormProvider.notifier)
                            .updatePhoneNumber(customer.phoneNumber);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        )
        : SizedBox.shrink();
  }

  Widget _buildAddressField(CustomerFormState customerFormState) {
    return CustomTextField(
      controller: addressController,
      hintText: customerFormState.fieldConfigs['address']!.hintText,
      label: customerFormState.fieldConfigs['address']!.title,
      keyboardType: TextInputType.streetAddress,
      filled: true,
      prefixIcon: AppIcon(
        defaultIcon: TablerIcons.location,
        win11IconPath: ImageAssets.win11Location,
        size: 20.spMin,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lIconColor,
      ),
      validator: (value) {
        if (customerFormState.fieldConfigs['address']!.isRequired &&
            (value == null || value.isEmpty)) {
          return customerFormState.fieldConfigs['address']!.validatorText;
        }
        return null;
      },
      onChange: (value) {
        ref.read(customerFormProvider.notifier).updateAddress(value ?? '');
        return null;
      },
    );
  }

  Widget _buildPhoneField(CustomerFormState customerFormState) {
    return CustomTextField(
      controller: phoneController,
      hintText: customerFormState.fieldConfigs['phoneNumber']!.hintText,
      label: customerFormState.fieldConfigs['phoneNumber']!.title,
      keyboardType: TextInputType.phone,
      filled: true,
      prefixIcon: AppIcon(
        defaultIcon: Icons.phone,
        win11IconPath: ImageAssets.win11Phone,
        size: 20.spMin,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lIconColor,
      ),
      validator: (value) {
        if (customerFormState.fieldConfigs['phoneNumber']!.isRequired &&
            (value == null || value.isEmpty)) {
          return customerFormState.fieldConfigs['phoneNumber']!.validatorText;
        }
        if (value != null &&
            value.isNotEmpty &&
            !RegExp(r'^\d{10,15}$').hasMatch(value)) {
          return 'Enter a valid phone number (10-15 digits)';
        }
        return null;
      },
      onChange: (value) {
        ref.read(customerFormProvider.notifier).updatePhoneNumber(value ?? '');
        return null;
      },
    );
  }

  Widget _buildPaymentStatusField(CustomerFormState customerFormState) {
    return AppDropdown<String>(
      filled: true,
      label: customerFormState.fieldConfigs['paymentStatus']!.title,
      hintText: customerFormState.fieldConfigs['paymentStatus']!.hintText,
      items: ['Paid', 'Pending'],
      value: statusController.text,
      onChanged: (value) {
        statusController.text = value ?? 'Pending';
        ref
            .read(customerFormProvider.notifier)
            .updatePaymentStatus(value ?? 'Pending');
      },
      prefixIcon: AppIcon(
        defaultIcon: Icons.payment,
        win11IconPath: ImageAssets.win11Cash,
        size: 20.spMin,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lIconColor,
      ),
      validator: (value) {
        if (customerFormState.fieldConfigs['paymentStatus']!.isRequired &&
            (value == null || value.isEmpty)) {
          return customerFormState.fieldConfigs['paymentStatus']!.validatorText;
        }
        return null;
      },
    );
  }

  Widget _buildPaymentMethodField(CustomerFormState customerFormState) {
    return AppDropdown<String>(
      filled: true,
      label: customerFormState.fieldConfigs['paymentMethod']!.title,
      hintText: customerFormState.fieldConfigs['paymentMethod']!.hintText,
      items: ['Cash', 'Online Pay'],
      value:
          paymentMethodController.text.isEmpty
              ? null
              : paymentMethodController.text,
      onChanged: (value) {
        paymentMethodController.text = value ?? '';
        ref.read(customerFormProvider.notifier).updatePaymentMethod(value);
      },
      prefixIcon: AppIcon(
        defaultIcon: Icons.payment,
        win11IconPath: ImageAssets.win11Card,
        size: 20.spMin,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lIconColor,
      ),
      validator: (value) {
        if (customerFormState.fieldConfigs['paymentMethod']!.isRequired &&
            (value == null || value.isEmpty)) {
          return customerFormState.fieldConfigs['paymentMethod']!.validatorText;
        }
        return null;
      },
    );
  }

  Widget _buildDiscountField(CustomerFormState customerFormState) {
    final editState = ref.watch(editBillProvider(widget.bill));
    final totalAmount = editState.updatedItems.fold<double>(
      0.0,
      (sum, item) =>
          sum + item.price * (editState.updatedQuantities[item.id] ?? 1),
    );
    return CustomTextField(
      controller: discountController,
      hintText:
          '${customerFormState.fieldConfigs['discount']!.hintText} (max: Rs.${totalAmount.toStringAsFixed(0)})',
      label: customerFormState.fieldConfigs['discount']!.title,
      keyboardType: TextInputType.number,
      filled: true,
      prefixIcon: AppIcon(
        defaultIcon: Icons.discount,
        win11IconPath: ImageAssets.win11PriceTag,
        size: 20.spMin,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lIconColor,
      ),
      validator: (value) {
        if (customerFormState.fieldConfigs['discount']!.isRequired &&
            (value == null || value.isEmpty)) {
          return customerFormState.fieldConfigs['discount']!.validatorText;
        }
        final amt = double.tryParse(value ?? '');
        if (value != null && value.isNotEmpty) {
          if (amt == null) {
            return 'Enter a valid number';
          }
          if (amt > totalAmount) {
            return 'Cannot exceed total: Rs.${totalAmount.toStringAsFixed(0)}';
          }
          if (amt < 0) {
            return 'Discount cannot be negative';
          }
        }
        return null;
      },
      onChange: (value) {
        ref.read(customerFormProvider.notifier).updateDiscount(value ?? '');
        return null;
      },
    );
  }

  Widget _buildPaidAmountField(CustomerFormState customerFormState) {
    final editState = ref.watch(editBillProvider(widget.bill));
    final totalAmount = editState.updatedItems.fold<double>(
      0.0,
      (sum, item) =>
          sum + item.price * (editState.updatedQuantities[item.id] ?? 1),
    );
    final discount = double.tryParse(discountController.text) ?? 0.0;
    final paidAmount = double.tryParse(paidAmountController.text) ?? 0.0;

    // Use PaymentCalculator for consistent calculations
    final pendingAmount = PaymentCalculator.calculatePendingAmount(
      totalAmount: totalAmount,
      discount: discount,
      paidAmount: paidAmount,
    );
    final paymentPercentage = PaymentCalculator.calculatePaymentPercentage(
      totalAmount: totalAmount,
      discount: discount,
      paidAmount: paidAmount,
    );
    final totalAfterDiscount = PaymentCalculator.calculateTotalAfterDiscount(
      totalAmount: totalAmount,
      discount: discount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: paidAmountController,
          hintText:
              '${customerFormState.fieldConfigs['paidAmount']!.hintText} (max: Rs.${totalAfterDiscount.toStringAsFixed(0)})',
          label: customerFormState.fieldConfigs['paidAmount']!.title,
          keyboardType: TextInputType.number,
          filled: true,
          prefixIcon: AppIcon(
            defaultIcon: Icons.money,
            win11IconPath: ImageAssets.win11DollarBag,
            size: 20.spMin,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : AppColors.lIconColor,
          ),
          validator: (value) {
            if (customerFormState.fieldConfigs['paidAmount']!.isRequired &&
                (value == null || value.isEmpty)) {
              return customerFormState
                  .fieldConfigs['paidAmount']!
                  .validatorText;
            }
            final amt = double.tryParse(value ?? '');
            if (value != null && value.isNotEmpty) {
              if (amt == null) {
                return 'Enter a valid number';
              }
              if (amt > totalAfterDiscount) {
                return 'Cannot exceed total: Rs.${totalAfterDiscount.toStringAsFixed(0)}';
              }
              if (amt < 0) {
                return 'Amount cannot be negative';
              }
            }
            return null;
          },
          onChange: (value) {
            ref
                .read(customerFormProvider.notifier)
                .updatePaidAmount(value ?? '');
            return null;
          },
        ),
        SizedBox(height: 8.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            mdText(
              text: 'Pending Amount:',
              color: Colors.grey,
            ),
            mdText(
              text: 'Rs.${pendingAmount.toStringAsFixed(0)}',
              color: pendingAmount > 0 ? Colors.red : Colors.green,
            ),
          ],
        ),
        if (paidAmount > 0) ...[
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              smText(
                text: 'Payment Progress:',
                color: Colors.grey,
              ),
              smText(
                text: '${paymentPercentage.toStringAsFixed(1)}%',
                color: paymentPercentage >= 100 ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildItemsTable() {
    final editState = ref.watch(editBillProvider(widget.bill));
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.w, horizontal: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            mdTextBold(text: 'Items'),
            SizedBox(height: 8.h),
            SizedBox(
              height: editState.updatedItems.length * 50.h + 50.h,
              child: DataTable2(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey),
                ),
                headingRowDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                columnSpacing: 5.w,
                horizontalMargin: 10.w,
                dividerThickness: 0,
                headingRowColor: WidgetStateProperty.all(
                  (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.primary),
                ),
                headingTextStyle: TextStyle(
                  fontSize: 12.spMin,
                  fontWeight: FontWeight.bold,
                ),
                dataTextStyle: TextStyle(
                  fontSize: 12.spMin,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                ),
                columns: [
                  DataColumn2(
                    label: smTextBold(text: 'Name'),
                    size: ColumnSize.L,
                  ),
                  DataColumn2(
                    label: smTextBold(text: 'Qty'),
                    size: ColumnSize.M,
                  ),
                  DataColumn2(
                    label: smTextBold(text: 'Unit Price'),
                    size: ColumnSize.M,
                    numeric: true,
                  ),
                  DataColumn2(
                    label: smTextBold(text: 'Total'),
                    size: ColumnSize.M,
                    numeric: true,
                  ),
                  DataColumn2(
                    label: smTextBold(text: 'Actions'),
                    size: ColumnSize.S,
                  ),
                ],
                rows:
                    editState.updatedItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final qty = editState.updatedQuantities[item.id] ?? 1;
                      final itemTotal = item.price * qty;
                      return DataRow2(
                        cells: [
                          DataCell(smText(text: item.name)),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: AppIcon(
                                    defaultIcon: Icons.remove,
                                    size: 16.spMin,
                                  ),
                                  onPressed:
                                      qty > 1
                                          ? () {
                                            ref
                                                .read(
                                                  editBillProvider(
                                                    widget.bill,
                                                  ).notifier,
                                                )
                                                .decrementQuantity(item.id);
                                          }
                                          : null,
                                ),
                                smText(text: qty.toString()),
                                IconButton(
                                  icon: AppIcon(
                                    defaultIcon: Icons.add,
                                    win11IconPath: ImageAssets.win11Add,
                                    size: 16.spMin,
                                  ),
                                  onPressed: () {
                                    ref
                                        .read(
                                          editBillProvider(
                                            widget.bill,
                                          ).notifier,
                                        )
                                        .incrementQuantity(item.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            smText(text: 'Rs.${item.price.toStringAsFixed(2)}'),
                          ),
                          DataCell(
                            smText(text: 'Rs.${itemTotal.toStringAsFixed(2)}'),
                          ),
                          DataCell(
                            IconButton(
                              icon: AppIcon(
                                defaultIcon: Icons.delete,
                                win11IconPath: ImageAssets.win11RecycleBin,
                                size: 16.spMin,
                                color: Colors.red,
                              ),
                              onPressed: () {
                                ref
                                    .read(
                                      editBillProvider(widget.bill).notifier,
                                    )
                                    .removeItem(index);
                              },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(CustomerFormState customerFormState) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customerFormState.fieldConfigs['name']!.isShow) ...[
            _buildNameField(customerFormState),
            _buildSuggestions(),
            SizedBox(height: 16.h),
          ],
          if (customerFormState.fieldConfigs['address']!.isShow) ...[
            _buildAddressField(customerFormState),
            SizedBox(height: 16.h),
          ],
          if (customerFormState.fieldConfigs['phoneNumber']!.isShow) ...[
            _buildPhoneField(customerFormState),
            SizedBox(height: 24.h),
          ],
          if (customerFormState.fieldConfigs['paymentStatus']!.isShow) ...[
            _buildPaymentStatusField(customerFormState),
            SizedBox(height: 24.h),
          ],
          if (customerFormState.fieldConfigs['paymentMethod']!.isShow) ...[
            _buildPaymentMethodField(customerFormState),
            SizedBox(height: 24.h),
          ],
          if (customerFormState.fieldConfigs['discount']!.isShow) ...[
            _buildDiscountField(customerFormState),
            SizedBox(height: 24.h),
          ],
          if (customerFormState.fieldConfigs['paidAmount']!.isShow &&
              statusController.text != 'Paid') ...[
            _buildPaidAmountField(customerFormState),
            SizedBox(height: 32.h),
          ],
          _buildItemsTable(),
          SizedBox(height: 32.h),
          AppButton().primaryButton(
            text: "Save & Update Bill",
            onPressed: _updateBill,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletDesktopLayout(CustomerFormState customerFormState) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (customerFormState.fieldConfigs['name']!.isShow ||
              customerFormState.fieldConfigs['phoneNumber']!.isShow)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (customerFormState.fieldConfigs['name']!.isShow)
                  Expanded(
                    child: Column(
                      children: [
                        _buildNameField(customerFormState),
                        _buildSuggestions(),
                      ],
                    ),
                  ),
                if (customerFormState.fieldConfigs['name']!.isShow &&
                    customerFormState.fieldConfigs['phoneNumber']!.isShow)
                  SizedBox(width: 16.w),
                if (customerFormState.fieldConfigs['phoneNumber']!.isShow)
                  Expanded(child: _buildPhoneField(customerFormState)),
              ],
            ),
          SizedBox(height: 16.h),
          if (customerFormState.fieldConfigs['address']!.isShow) ...[
            _buildAddressField(customerFormState),
            SizedBox(height: 24.h),
          ],
          if (customerFormState.fieldConfigs['paymentStatus']!.isShow ||
              customerFormState.fieldConfigs['paymentMethod']!.isShow)
            Row(
              children: [
                if (customerFormState.fieldConfigs['paymentStatus']!.isShow)
                  Expanded(child: _buildPaymentStatusField(customerFormState)),
                if (customerFormState.fieldConfigs['paymentStatus']!.isShow &&
                    customerFormState.fieldConfigs['paymentMethod']!.isShow)
                  SizedBox(width: 16.w),
                if (customerFormState.fieldConfigs['paymentMethod']!.isShow)
                  Expanded(child: _buildPaymentMethodField(customerFormState)),
              ],
            ),
          SizedBox(height: 24.h),
          if (customerFormState.fieldConfigs['discount']!.isShow) ...[
            _buildDiscountField(customerFormState),
            SizedBox(height: 24.h),
          ],
          if (customerFormState.fieldConfigs['paidAmount']!.isShow &&
              statusController.text != 'Paid') ...[
            _buildPaidAmountField(customerFormState),
            SizedBox(height: 32.h),
          ],
          _buildItemsTable(),
          SizedBox(height: 32.h),
          AppButton().primaryButton(
            text: "Save & Update Bill",
            onPressed: _updateBill,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerFormState = ref.watch(customerFormProvider);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Edit Bill #${widget.bill.id}',
        context: context,
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveWrapper(
          mobile: _buildMobileLayout(customerFormState),
          tablet: _buildTabletDesktopLayout(customerFormState),
          desktop: _buildTabletDesktopLayout(customerFormState),
        ),
      ),
    );
  }
}
