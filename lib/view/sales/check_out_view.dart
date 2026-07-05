// ignore_for_file: use_build_context_synchronously

import 'dart:math'; // Added for random generation
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_bar_widget.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_flushbar.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../models/coustomer_model.dart';
import '../../res/components/text_field_widget.dart';
import '../../view_models/providers/sales_provider.dart';
import '../../view_models/providers/checkout_provider.dart';
import '../../view_models/services/database/database_services.dart'
    hide databaseServiceProvider;
import '../../models/items_model.dart';
import '../../view_models/states/sales_state.dart';
import '../../utils/payment_calculator.dart';
import '../home/rapper.dart';

class CustomerFormState {
  final String? name;
  final String? address;
  final String? phoneNumber;
  final double? paidAmount;
  final bool? paymentStatus;
  final String? paymentMethod;
  final double? discount;
  final Map<String, FieldConfig> fieldConfigs;
  final String? errorMessage;
  final bool isLoading;

  CustomerFormState({
    this.name,
    this.address,
    this.phoneNumber,
    this.paidAmount,
    this.paymentStatus,
    this.paymentMethod,
    this.discount,
    required this.fieldConfigs,
    this.errorMessage,
    this.isLoading = false,
  });

  CustomerFormState copyWith({
    String? name,
    String? address,
    String? phoneNumber,
    double? paidAmount,
    bool? paymentStatus,
    String? paymentMethod,
    double? discount,
    Map<String, FieldConfig>? fieldConfigs,
    String? errorMessage,
    bool? isLoading,
  }) {
    return CustomerFormState(
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      discount: discount ?? this.discount,
      fieldConfigs: fieldConfigs ?? this.fieldConfigs,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CustomerFormNotifier extends StateNotifier<CustomerFormState> {
  final DatabaseService _databaseService;

  CustomerFormNotifier(this._databaseService)
    : super(CustomerFormState(fieldConfigs: _loadDefaultFieldConfigs()));

  static Map<String, FieldConfig> _loadDefaultFieldConfigs() {
    return {
      'name': FieldConfig.initial('name', WidgetType.textField),
      'address': FieldConfig.initial('address', WidgetType.textField),
      'phoneNumber': FieldConfig.initial('phoneNumber', WidgetType.textField),
      'paidAmount': FieldConfig.initial('paidAmount', WidgetType.textField),
      'paymentStatus': FieldConfig.initial(
        'paymentStatus',
        WidgetType.dropdown,
      ),
      'paymentMethod': FieldConfig.initial(
        'paymentMethod',
        WidgetType.dropdown,
      ),
      'discount': FieldConfig.initial('discount', WidgetType.textField),
    };
  }

  void updateName(String name) {
    state = state.copyWith(name: name, errorMessage: null);
  }

  void updateAddress(String address) {
    state = state.copyWith(
      address: address.isEmpty ? null : address,
      errorMessage: null,
    );
  }

  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(
      phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
      errorMessage: null,
    );
  }

  void updatePaidAmount(String paidAmount) {
    final parsedAmount = double.tryParse(paidAmount);
    state = state.copyWith(paidAmount: parsedAmount, errorMessage: null);
  }

  void updatePaymentStatus(String status) {
    state = state.copyWith(paymentStatus: status == 'Paid', errorMessage: null);
  }

  void updatePaymentMethod(String? method) {
    state = state.copyWith(paymentMethod: method, errorMessage: null);
  }

  void updateDiscount(String discount) {
    final parsedDiscount = double.tryParse(discount);
    state = state.copyWith(discount: parsedDiscount, errorMessage: null);
  }

  void updateFieldConfig(
    String fieldName, {
    bool? isShow,
    bool? isRequired,
    String? hintText,
    String? validatorText,
    String? title,
    WidgetType? widgetType,
  }) {
    final updatedConfigs = Map<String, FieldConfig>.from(state.fieldConfigs);
    updatedConfigs[fieldName] = updatedConfigs[fieldName]!.copyWith(
      isShow: isShow,
      isRequired: isRequired,
      hintText: hintText,
      validatorText: validatorText,
      title: title,
      widgetType: widgetType,
    );
    state = state.copyWith(fieldConfigs: updatedConfigs);
    _saveFieldConfigs(updatedConfigs);
  }

  Future<void> _saveFieldConfigs(Map<String, FieldConfig> fieldConfigs) async {
    try {
      await _databaseService.saveCustomerFieldConfigs(fieldConfigs);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save field configs: $e');
    }
  }
}

final customerFormProvider =
    StateNotifierProvider<CustomerFormNotifier, CustomerFormState>(
      (ref) => CustomerFormNotifier(ref.read(databaseServiceProvider)),
    );

class CustomerPaymentScreen extends ConsumerStatefulWidget {
  final double totalAmount;
  final double discount;

  const CustomerPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.discount,
  });

  @override
  ConsumerState<CustomerPaymentScreen> createState() =>
      _CustomerPaymentScreenState();
}

class _CustomerPaymentScreenState extends ConsumerState<CustomerPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  // Anchor + overlay for the customer-name suggestions so they float over the
  // fields below (like a real dropdown) instead of taking layout space and
  // pushing the form down / leaving a gap.
  final LayerLink _nameFieldLink = LayerLink();
  final OverlayPortalController _suggestionsPortal = OverlayPortalController();
  double _nameFieldWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final customers = await ref.read(databaseServiceProvider).getCustomers();
      ref.read(checkoutProvider.notifier).loadCustomers(customers);
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

    final salesState = ref.read(salesProvider);
    paidAmountController.text =
        salesState.paidAmount > 0
            ? salesState.paidAmount.toStringAsFixed(0)
            : '';
    discountController.text =
        salesState.discount > 0 ? salesState.discount.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    paidAmountController.dispose();
    discountController.dispose();
    super.dispose();
  }

  void _setCheckoutMode(String mode) {
    final random = Random();

    if (mode == 'walk-in') {
      ref.read(checkoutProvider.notifier).toggleWalkIn(true);
      final randomBillId =
          'BILL-${random.nextInt(10000).toString().padLeft(4, '0')}';
      nameController.text = randomBillId;
      addressController.text = '';
      phoneController.text = '';
      ref.read(customerFormProvider.notifier).updateName(randomBillId);
      ref.read(customerFormProvider.notifier).updateAddress('');
      ref.read(customerFormProvider.notifier).updatePhoneNumber('');
      AppFlushbar.info(
        context,
        message: 'Walk-in: Generated bill ID $randomBillId',
      );
    } else if (mode == 'test-bill') {
      ref.read(checkoutProvider.notifier).toggleTestBill(true);
      final randomTestId =
          'TEST-${random.nextInt(10000).toString().padLeft(4, '0')}';
      nameController.text = randomTestId;
      addressController.text = '';
      phoneController.text = '';
      ref.read(customerFormProvider.notifier).updateName(randomTestId);
      ref.read(customerFormProvider.notifier).updateAddress('');
      ref.read(customerFormProvider.notifier).updatePhoneNumber('');
      AppFlushbar.info(
        context,
        message: 'Test Bill: PDF only, no data will be saved',
      );
    } else {
      // Customer mode
      ref.read(checkoutProvider.notifier).setCustomerMode();
      nameController.text = '';
      addressController.text = '';
      phoneController.text = '';
      ref.read(customerFormProvider.notifier).updateName('');
      ref.read(customerFormProvider.notifier).updateAddress('');
      ref.read(customerFormProvider.notifier).updatePhoneNumber('');
    }
  }

  Widget _buildNameField(
    CustomerFormState customerFormState,
    bool isWalkIn, {
    bool isTestBill = false,
    List<Customer> filteredCustomers = const [],
  }) {
    // Anchor the suggestions overlay to the text field. The overlay floats over
    // the widgets below (real dropdown behaviour) so it never pushes the form
    // down or leaves a reserved gap when hidden.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _nameFieldLink,
          child: OverlayPortal(
            controller: _suggestionsPortal,
            overlayChildBuilder: (context) {
              return _buildSuggestionsOverlay(filteredCustomers, isWalkIn);
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                _nameFieldWidth = constraints.maxWidth;
                return CustomTextField(
                  controller: nameController,
                  hintText: customerFormState.fieldConfigs['name']!.hintText,
                  label: customerFormState.fieldConfigs['name']!.title,
                  keyboardType: TextInputType.name,
                  prefixIcon: Icon(
                    Icons.person,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppColors.lIconColor,
                  ),
                  enabled: !isWalkIn,
                  readOnly: isWalkIn,
                  validator: (value) {
                    if (customerFormState.fieldConfigs['name']!.isRequired &&
                        (value == null || value.isEmpty)) {
                      return customerFormState
                          .fieldConfigs['name']!
                          .validatorText;
                    }
                    return null;
                  },
                  onChange:
                      isWalkIn
                          ? null
                          : (value) {
                            ref
                                .read(customerFormProvider.notifier)
                                .updateName(value ?? '');
                            ref
                                .read(checkoutProvider.notifier)
                                .filterCustomers(value ?? '');
                            return null;
                          },
                );
              },
            ),
          ),
        ),
        if (isWalkIn) ...[
          SizedBox(height: 4.h),
          mdText(
            text: isTestBill
                ? 'Test bill - PDF only, no data saved'
                : 'Walk-in customer - no data saved',
            color: isTestBill ? Colors.orange : Colors.grey,
          ),
        ],
      ],
    );
  }

  /// Floating suggestions list, rendered in an [Overlay] and positioned right
  /// under the name field via [CompositedTransformFollower]. Because it lives
  /// in the overlay it does not occupy layout space in the form.
  Widget _buildSuggestionsOverlay(
    List<Customer> filteredCustomers,
    bool isWalkIn,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      width: _nameFieldWidth,
      child: CompositedTransformFollower(
        link: _nameFieldLink,
        showWhenUnlinked: false,
        // Anchor the top of the list to the BOTTOM of the field so it always
        // drops under it (never covering it), regardless of field height.
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: Offset(0, 6.spMin),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.grey800 : AppColors.grey100,
                borderRadius: BorderRadius.circular(10.spMin),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 220.spMin),
                child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.all(6.spMin),
                itemCount: filteredCustomers.length,
                separatorBuilder: (_, __) => SizedBox(height: 6.spMin),
                itemBuilder: (context, index) {
                  final customer = filteredCustomers[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.spMin,
                        vertical: 2.spMin,
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 14.spMin,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                          ),
                          SizedBox(width: 6.spMin),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 2.spMin),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_city,
                                size: 14.spMin,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              SizedBox(width: 6.spMin),
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
                              Icon(
                                Icons.phone,
                                size: 14.spMin,
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                              ),
                              SizedBox(width: 6.spMin),
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
                        ref.read(checkoutProvider.notifier).hideSuggestions();
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
          ),
        ),
      ),
    );
  }

  Widget _buildAddressField(
    CustomerFormState customerFormState,
    bool isWalkIn,
  ) {
    return CustomTextField(
      controller: addressController,
      hintText:
          isWalkIn
              ? 'walk-in'
              : customerFormState.fieldConfigs['address']!.hintText,
      label: customerFormState.fieldConfigs['address']!.title,
      keyboardType: TextInputType.streetAddress,
      prefixIcon: Icon(
        TablerIcons.location,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lIconColor,
      ),
      enabled: !isWalkIn,
      readOnly: isWalkIn,
      validator:
          isWalkIn
              ? null
              : (value) {
                if (customerFormState.fieldConfigs['address']!.isRequired &&
                    (value == null || value.isEmpty)) {
                  return customerFormState
                      .fieldConfigs['address']!
                      .validatorText;
                }
                return null;
              },
      onChange:
          isWalkIn
              ? null
              : (value) {
                ref
                    .read(customerFormProvider.notifier)
                    .updateAddress(value ?? '');
                return null;
              },
    );
  }

  Widget _buildPhoneField(CustomerFormState customerFormState, bool isWalkIn) {
    return CustomTextField(
      controller: phoneController,
      hintText:
          isWalkIn
              ? 'walk-in'
              : customerFormState.fieldConfigs['phoneNumber']!.hintText,
      label: customerFormState.fieldConfigs['phoneNumber']!.title,
      keyboardType: TextInputType.phone,
      prefixIcon: Icon(
        Icons.phone,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.lIconColor,
      ),
      enabled: !isWalkIn,
      readOnly: isWalkIn,
      validator:
          isWalkIn
              ? null
              : (value) {
                if (customerFormState.fieldConfigs['phoneNumber']!.isRequired &&
                    (value == null || value.isEmpty)) {
                  return customerFormState
                      .fieldConfigs['phoneNumber']!
                      .validatorText;
                }
                if (value != null &&
                    value.isNotEmpty &&
                    !RegExp(r'^\d{10,15}$').hasMatch(value)) {
                  return 'Enter a valid phone number (10-15 digits)';
                }
                return null;
              },
      onChange:
          isWalkIn
              ? null
              : (value) {
                ref
                    .read(customerFormProvider.notifier)
                    .updatePhoneNumber(value ?? '');
                return null;
              },
    );
  }

  Widget _buildPaymentStatusField(
    CustomerFormState customerFormState,
    SalesState salesState,
  ) {
    return AppDropdown<String>(
      label: customerFormState.fieldConfigs['paymentStatus']!.title,
      hintText: customerFormState.fieldConfigs['paymentStatus']!.hintText,
      items: ['Paid', 'Pending'],
      value: salesState.isPaid ? 'Paid' : 'Pending',
      onChanged: (value) {
        ref.read(salesProvider.notifier).setPaymentStatus(value == 'Paid');
        ref
            .read(customerFormProvider.notifier)
            .updatePaymentStatus(value ?? 'Pending');
      },
      prefixIcon: Icon(
        Icons.payment,
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

  Widget _buildPaymentMethodField(
    CustomerFormState customerFormState,
    SalesState salesState,
  ) {
    return AppDropdown<String>(
      label: customerFormState.fieldConfigs['paymentMethod']!.title,
      hintText: customerFormState.fieldConfigs['paymentMethod']!.hintText,
      items: ['Cash', 'Online Pay'],
      value: salesState.paymentMethod,
      onChanged: (value) {
        ref.read(salesProvider.notifier).setPaymentMethod(value);
        ref.read(customerFormProvider.notifier).updatePaymentMethod(value);
      },
      prefixIcon: Icon(
        Icons.payment,
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
    return CustomTextField(
      controller: discountController,
      hintText:
          '${customerFormState.fieldConfigs['discount']!.hintText} (max: Rs.${widget.totalAmount.toStringAsFixed(0)})',
      label: customerFormState.fieldConfigs['discount']!.title,
      keyboardType: TextInputType.number,
      prefixIcon: Icon(
        Icons.discount,
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
          if (amt > widget.totalAmount) {
            return 'Cannot exceed total: Rs.${widget.totalAmount.toStringAsFixed(0)}';
          }
          if (amt < 0) {
            return 'Discount cannot be negative';
          }
        }
        return null;
      },
      onChange: (value) {
        final amt = double.tryParse(value ?? '') ?? 0.0;
        ref.read(salesProvider.notifier).setDiscount(amt);
        ref.read(customerFormProvider.notifier).updateDiscount(value ?? '');
        return null;
      },
    );
  }

  Widget _buildPaidAmountField(
    CustomerFormState customerFormState,
    SalesState salesState,
    double totalAfterDiscount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: paidAmountController,
          hintText:
              '${customerFormState.fieldConfigs['paidAmount']!.hintText} (max: Rs.${totalAfterDiscount.toStringAsFixed(0)})',
          label: customerFormState.fieldConfigs['paidAmount']!.title,
          keyboardType: TextInputType.number,
          prefixIcon: Icon(
            Icons.money,
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
            debugPrint('🔵 Paid Amount Field Changed: "$value"');
            final amt = double.tryParse(value ?? '') ?? 0.0;
            debugPrint('🔵 Parsed Amount: $amt');
            ref.read(salesProvider.notifier).setPaidAmount(amt);
            debugPrint('🔵 Set to salesProvider');
            ref
                .read(customerFormProvider.notifier)
                .updatePaidAmount(value ?? '');
            debugPrint('🔵 Set to customerFormProvider');
            return null;
          },
        ),
        SizedBox(height: 8.h),
        Consumer(
          builder: (context, ref, child) {
            final currentSalesState = ref.watch(salesProvider);
            final pendingAmount = PaymentCalculator.calculatePendingAmount(
              totalAmount: widget.totalAmount,
              discount: customerFormState.discount ?? widget.discount,
              paidAmount: currentSalesState.paidAmount,
            );
            final paymentPercentage =
                PaymentCalculator.calculatePaymentPercentage(
                  totalAmount: widget.totalAmount,
                  discount: customerFormState.discount ?? widget.discount,
                  paidAmount: currentSalesState.paidAmount,
                );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    mdText(text: 'Pending Amount:', color: Colors.grey),
                    mdText(
                      text: 'Rs.${pendingAmount.toStringAsFixed(0)}',
                      color: pendingAmount > 0 ? Colors.red : Colors.green,
                    ),
                  ],
                ),
                if (currentSalesState.paidAmount > 0) ...[
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      smText(text: 'Payment Progress:', color: Colors.grey),
                      smText(
                        text: '${paymentPercentage.toStringAsFixed(1)}%',
                        color:
                            paymentPercentage >= 100
                                ? Colors.green
                                : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    CustomerFormState customerFormState,
    SalesState salesState,
    double totalAfterDiscount,
    bool isWalkIn,
    List<Customer> filteredCustomers,
    bool showSuggestions, {
    bool isTestBill = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customerFormState.fieldConfigs['name']!.isShow) ...[
          _buildNameField(
            customerFormState,
            isWalkIn,
            isTestBill: isTestBill,
            filteredCustomers: filteredCustomers,
          ),
          SizedBox(height: 16.h),
        ],
        if (customerFormState.fieldConfigs['address']!.isShow) ...[
          _buildAddressField(customerFormState, isWalkIn),
          SizedBox(height: 16.h),
        ],
        if (customerFormState.fieldConfigs['phoneNumber']!.isShow) ...[
          _buildPhoneField(customerFormState, isWalkIn),
          SizedBox(height: 24.h),
        ],
        if (customerFormState.fieldConfigs['paymentStatus']!.isShow) ...[
          _buildPaymentStatusField(customerFormState, salesState),
          SizedBox(height: 24.h),
        ],
        if (customerFormState.fieldConfigs['paymentMethod']!.isShow) ...[
          _buildPaymentMethodField(customerFormState, salesState),
          SizedBox(height: 24.h),
        ],
        if (customerFormState.fieldConfigs['discount']!.isShow) ...[
          _buildDiscountField(customerFormState),
          SizedBox(height: 24.h),
        ],
        if (customerFormState.fieldConfigs['paidAmount']!.isShow &&
            !salesState.isPaid) ...[
          _buildPaidAmountField(
            customerFormState,
            salesState,
            totalAfterDiscount,
          ),
          SizedBox(height: 32.h),
        ],
        AppButton().primaryButton(
          text: isTestBill ? "Generate Test Bill" : "Save & Complete Sale",
          onPressed: () {
            debugPrint(
              '========== CHECKOUT: Save & Complete Sale Button Pressed ==========',
            );
            debugPrint(
              'Form Validation Result: ${_formKey.currentState!.validate()}',
            );

            if (_formKey.currentState!.validate()) {
              // READ THE CURRENT STATE HERE, NOT THE OLD ONE!
              final currentSalesState = ref.read(salesProvider);

              debugPrint('--- Payment Information ---');
              debugPrint('Total Amount: ${widget.totalAmount}');
              debugPrint(
                'Discount: ${customerFormState.discount ?? widget.discount}',
              );
              debugPrint('Total After Discount: $totalAfterDiscount');
              debugPrint(
                'Payment Status (isPaid): ${currentSalesState.isPaid}',
              );
              debugPrint('Paid Amount: ${currentSalesState.paidAmount}');
              debugPrint('Payment Method: ${currentSalesState.paymentMethod}');

              final pendingAmount = PaymentCalculator.calculatePendingAmount(
                totalAmount: widget.totalAmount,
                discount: customerFormState.discount ?? widget.discount,
                paidAmount: currentSalesState.paidAmount,
              );
              debugPrint('Pending Amount (Calculated): $pendingAmount');

              debugPrint('--- Customer Information ---');
              debugPrint('Customer Name: ${nameController.text}');
              debugPrint('Address: ${addressController.text}');
              debugPrint('Phone: ${phoneController.text}');
              debugPrint('Is Walk-in: $isWalkIn');

              if (!currentSalesState.isPaid &&
                  currentSalesState.paidAmount > totalAfterDiscount) {
                debugPrint('ERROR: Paid amount exceeds total!');
                AppFlushbar.error(
                  context,
                  message: 'Paid amount cannot exceed total',
                );
                return;
              }

              final customerData =
                  isWalkIn
                      ? {
                        'name': nameController.text,
                        'address': null,
                        'phoneNumber': null,
                        'isWalkIn': !isTestBill,
                        'isTestBill': isTestBill,
                      }
                      : {
                        'name': nameController.text,
                        'address': addressController.text,
                        'phoneNumber': phoneController.text,
                        'isWalkIn': false,
                        'isTestBill': false,
                      };

              debugPrint('--- Customer Data to Return ---');
              debugPrint('Customer Data: $customerData');
              debugPrint(
                '========== CHECKOUT: Returning to Previous Screen ==========\n',
              );

              Navigator.pop(context, customerData);
            } else {
              debugPrint('ERROR: Form validation failed!');
            }
          },
        ),
      ],
    );
  }

  Widget _buildTabletDesktopLayout(
    CustomerFormState customerFormState,
    SalesState salesState,
    double totalAfterDiscount,
    bool isWalkIn,
    List<Customer> filteredCustomers,
    bool showSuggestions, {
    bool isTestBill = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customerFormState.fieldConfigs['name']!.isShow ||
            customerFormState.fieldConfigs['phoneNumber']!.isShow)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (customerFormState.fieldConfigs['name']!.isShow)
                Expanded(
                  child: _buildNameField(
                    customerFormState,
                    isWalkIn,
                    isTestBill: isTestBill,
                    filteredCustomers: filteredCustomers,
                  ),
                ),
              if (customerFormState.fieldConfigs['name']!.isShow &&
                  customerFormState.fieldConfigs['phoneNumber']!.isShow)
                SizedBox(width: 16.w),
              if (customerFormState.fieldConfigs['phoneNumber']!.isShow)
                Expanded(child: _buildPhoneField(customerFormState, isWalkIn)),
            ],
          ),
        SizedBox(height: 16.h),
        if (customerFormState.fieldConfigs['address']!.isShow) ...[
          _buildAddressField(customerFormState, isWalkIn),
          SizedBox(height: 24.h),
        ],
        if (customerFormState.fieldConfigs['paymentStatus']!.isShow ||
            customerFormState.fieldConfigs['paymentMethod']!.isShow)
          Row(
            children: [
              if (customerFormState.fieldConfigs['paymentStatus']!.isShow)
                Expanded(
                  child: _buildPaymentStatusField(
                    customerFormState,
                    salesState,
                  ),
                ),
              if (customerFormState.fieldConfigs['paymentStatus']!.isShow &&
                  customerFormState.fieldConfigs['paymentMethod']!.isShow)
                SizedBox(width: 16.w),
              if (customerFormState.fieldConfigs['paymentMethod']!.isShow)
                Expanded(
                  child: _buildPaymentMethodField(
                    customerFormState,
                    salesState,
                  ),
                ),
            ],
          ),
        SizedBox(height: 24.h),
        if (customerFormState.fieldConfigs['discount']!.isShow) ...[
          _buildDiscountField(customerFormState),
          SizedBox(height: 24.h),
        ],
        if (customerFormState.fieldConfigs['paidAmount']!.isShow &&
            !salesState.isPaid) ...[
          _buildPaidAmountField(
            customerFormState,
            salesState,
            totalAfterDiscount,
          ),
          SizedBox(height: 32.h),
        ],
        AppButton().primaryButton(
          text: isTestBill ? "Generate Test Bill" : "Save & Complete Sale",
          onPressed: () {
            debugPrint(
              '========== CHECKOUT (Desktop/Tablet): Save & Complete Sale Button Pressed ==========',
            );
            debugPrint(
              'Form Validation Result: ${_formKey.currentState!.validate()}',
            );

            if (_formKey.currentState!.validate()) {
              // READ THE CURRENT STATE HERE, NOT THE OLD ONE!
              final currentSalesState = ref.read(salesProvider);

              debugPrint('--- Payment Information ---');
              debugPrint('Total Amount: ${widget.totalAmount}');
              debugPrint(
                'Discount: ${customerFormState.discount ?? widget.discount}',
              );
              debugPrint('Total After Discount: $totalAfterDiscount');
              debugPrint(
                'Payment Status (isPaid): ${currentSalesState.isPaid}',
              );
              debugPrint('Paid Amount: ${currentSalesState.paidAmount}');
              debugPrint('Payment Method: ${currentSalesState.paymentMethod}');

              final pendingAmount = PaymentCalculator.calculatePendingAmount(
                totalAmount: widget.totalAmount,
                discount: customerFormState.discount ?? widget.discount,
                paidAmount: currentSalesState.paidAmount,
              );
              debugPrint('Pending Amount (Calculated): $pendingAmount');

              debugPrint('--- Customer Information ---');
              debugPrint('Customer Name: ${nameController.text}');
              debugPrint('Address: ${addressController.text}');
              debugPrint('Phone: ${phoneController.text}');
              debugPrint('Is Walk-in: $isWalkIn');

              if (!currentSalesState.isPaid &&
                  currentSalesState.paidAmount > totalAfterDiscount) {
                debugPrint('ERROR: Paid amount exceeds total!');
                AppFlushbar.error(
                  context,
                  message: 'Paid amount cannot exceed total',
                );
                return;
              }

              final customerData =
                  isWalkIn
                      ? {
                        'name': nameController.text,
                        'address': null,
                        'phoneNumber': null,
                        'isWalkIn': !isTestBill,
                        'isTestBill': isTestBill,
                      }
                      : {
                        'name': nameController.text,
                        'address': addressController.text,
                        'phoneNumber': phoneController.text,
                        'isWalkIn': false,
                        'isTestBill': false,
                      };

              debugPrint('--- Customer Data to Return ---');
              debugPrint('Customer Data: $customerData');
              debugPrint(
                '========== CHECKOUT (Desktop/Tablet): Returning to Previous Screen ==========\n',
              );

              Navigator.pop(context, customerData);
            } else {
              debugPrint('ERROR: Form validation failed!');
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesState = ref.watch(salesProvider);
    final customerFormState = ref.watch(customerFormProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final totalAfterDiscount =
        widget.totalAmount - (customerFormState.discount ?? widget.discount);

    // Show/hide the floating suggestions overlay to match state. Toggling must
    // happen outside build(), so defer to the next frame.
    final bool shouldShowSuggestions =
        checkoutState.showSuggestions &&
        checkoutState.filteredCustomers.isNotEmpty &&
        !(checkoutState.isWalkIn || checkoutState.isTestBill);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (shouldShowSuggestions) {
        _suggestionsPortal.show();
      } else {
        _suggestionsPortal.hide();
      }
    });

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: "Customer & Payment Info",
        context: context,
        actions: [
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  checkoutState.isTestBill
                      ? TablerIcons.test_pipe
                      : checkoutState.isWalkIn
                      ? TablerIcons.walk
                      : TablerIcons.user,
                  size: 18.spMin,
                ),
                SizedBox(width: 4.w),
                smText(
                  text: checkoutState.isTestBill
                      ? 'Test Bill'
                      : checkoutState.isWalkIn
                      ? 'Walk-in'
                      : 'Customer',
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                ),
                Icon(Icons.arrow_drop_down, size: 18.spMin),
              ],
            ),
            onSelected: _setCheckoutMode,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'customer',
                child: Row(
                  children: [
                    Icon(TablerIcons.user, size: 18.spMin),
                    SizedBox(width: 8.w),
                    const Text('Customer'),
                    if (!checkoutState.isWalkIn && !checkoutState.isTestBill)
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: Icon(Icons.check, size: 16.spMin, color: Colors.green),
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'walk-in',
                child: Row(
                  children: [
                    Icon(TablerIcons.walk, size: 18.spMin),
                    SizedBox(width: 8.w),
                    const Text('Walk-in'),
                    if (checkoutState.isWalkIn)
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: Icon(Icons.check, size: 16.spMin, color: Colors.green),
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'test-bill',
                child: Row(
                  children: [
                    Icon(TablerIcons.test_pipe, size: 18.spMin),
                    SizedBox(width: 8.w),
                    const Text('Test Bill'),
                    if (checkoutState.isTestBill)
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: Icon(Icons.check, size: 16.spMin, color: Colors.green),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: ResponsiveWrapper(
            mobile: _buildMobileLayout(
              customerFormState,
              salesState,
              totalAfterDiscount,
              checkoutState.isWalkIn || checkoutState.isTestBill,
              checkoutState.filteredCustomers,
              checkoutState.showSuggestions,
              isTestBill: checkoutState.isTestBill,
            ),
            tablet: _buildTabletDesktopLayout(
              customerFormState,
              salesState,
              totalAfterDiscount,
              checkoutState.isWalkIn || checkoutState.isTestBill,
              checkoutState.filteredCustomers,
              checkoutState.showSuggestions,
              isTestBill: checkoutState.isTestBill,
            ),
            desktop: _buildTabletDesktopLayout(
              customerFormState,
              salesState,
              totalAfterDiscount,
              checkoutState.isWalkIn || checkoutState.isTestBill,
              checkoutState.filteredCustomers,
              checkoutState.showSuggestions,
              isTestBill: checkoutState.isTestBill,
            ),
          ),
        ),
      ),
    );
  }
}
