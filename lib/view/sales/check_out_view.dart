// ignore_for_file: use_build_context_synchronously

import 'dart:math'; // Added for random generation
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_bar_widget.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_flushbar.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:uuid/uuid.dart';
import '../../models/coustomer_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/text_field_widget.dart';
import '../../view_models/providers/sales_provider.dart';
import '../../view_models/providers/checkout_provider.dart';
import '../../view_models/services/database/database_services.dart'
    hide databaseServiceProvider;
import '../../view_models/services/keyboard/app_keyboard_service.dart';
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

  /// Typed values for the user-defined custom fields, keyed by field key.
  final Map<String, dynamic> customValues;
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
    this.customValues = const {},
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
    Map<String, dynamic>? customValues,
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
      customValues: customValues ?? this.customValues,
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
    final configs = {
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
    // 'name' is a shared field key — the generic default is "Item Name"
    // (product form). This is the CUSTOMER checkout form, so use its proper
    // title / hint / validator.
    configs['name'] = configs['name']!.copyWith(
      title: 'Customer Name',
      hintText: 'Enter customer name',
      validatorText: 'Customer name is required',
    );
    return configs;
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

  /// Proper default titles for the customer checkout fields. This provider
  /// is only used for that form, so the raw-field-key fallback resolves to
  /// customer-appropriate names (not "Item Name").
  static const Map<String, String> _customerFieldTitles = {
    'name': 'Customer Name',
    'address': 'Address',
    'phoneNumber': 'Phone Number',
    'paidAmount': 'Paid Amount',
    'paymentStatus': 'Payment Status',
    'paymentMethod': 'Payment Method',
    'discount': 'Discount',
  };

  /// Corrects field titles coming from stored configs. Older app versions
  /// saved the raw field key (e.g. "phoneNumber", "paidAmount") as the
  /// title — map those back to the proper default — and the first letter
  /// is always capitalised.
  String _properTitle(String title, String fieldName, WidgetType widgetType) {
    final String trimmed = title.trim();
    final bool isRawKey =
        trimmed.isEmpty || trimmed.toLowerCase() == fieldName.toLowerCase();
    final String fixed =
        isRawKey
            ? (_customerFieldTitles[fieldName] ??
                FieldConfig.initial(fieldName, widgetType).title)
            : trimmed;
    if (fixed.isEmpty) {
      return trimmed;
    }
    return fixed[0].toUpperCase() + fixed.substring(1);
  }

  void updateFieldConfig(
    String fieldName, {
    bool? isShow,
    bool? isRequired,
    String? hintText,
    String? validatorText,
    String? title,
    WidgetType? widgetType,
    List<String>? options,
  }) {
    // Ensure the fallback title resolves with the right widget type.
    final WidgetType effectiveType =
        widgetType ?? state.fieldConfigs[fieldName]!.widgetType;
    final updatedConfigs = Map<String, FieldConfig>.from(state.fieldConfigs);
    updatedConfigs[fieldName] = updatedConfigs[fieldName]!.copyWith(
      isShow: isShow,
      isRequired: isRequired,
      hintText: hintText,
      validatorText: validatorText,
      title:
          title == null ? null : _properTitle(title, fieldName, effectiveType),
      widgetType: widgetType,
      options: options,
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

  /// Replaces the whole config map with the saved one (Settings + custom
  /// fields) WITHOUT persisting — used when a form first loads from storage.
  void replaceAllFieldConfigs(Map<String, FieldConfig> configs) {
    state = state.copyWith(
      fieldConfigs: Map<String, FieldConfig>.from(configs),
    );
  }

  /// Adds a user-defined custom field (Settings → Add Field) and persists it.
  /// Returns the generated field key (e.g. "custom_1a2b3c4d").
  String addFieldConfig(FieldConfig config) {
    final key = 'custom_${const Uuid().v4().substring(0, 8)}';
    final updatedConfigs = Map<String, FieldConfig>.from(state.fieldConfigs);
    updatedConfigs[key] = config.copyWith(isCustom: true);
    state = state.copyWith(fieldConfigs: updatedConfigs);
    _saveFieldConfigs(updatedConfigs);
    return key;
  }

  /// Removes a custom field from the checkout configuration.
  void deleteFieldConfig(String fieldName) {
    final updatedConfigs = Map<String, FieldConfig>.from(state.fieldConfigs);
    updatedConfigs.remove(fieldName);
    final updatedValues = Map<String, dynamic>.from(state.customValues);
    updatedValues.remove(fieldName);
    state = state.copyWith(
      fieldConfigs: updatedConfigs,
      customValues: updatedValues,
    );
    _saveFieldConfigs(updatedConfigs);
  }

  /// Stores the typed value of a custom field.
  void updateCustomField(String fieldName, dynamic value) {
    final updated = Map<String, dynamic>.from(state.customValues);
    if (value == null || (value is String && value.trim().isEmpty)) {
      updated.remove(fieldName);
    } else {
      updated[fieldName] = value;
    }
    state = state.copyWith(customValues: updated, errorMessage: null);
  }

  /// Replaces all custom field values at once (e.g. when clearing the form).
  void updateCustomValues(Map<String, dynamic> values) {
    state = state.copyWith(customValues: values, errorMessage: null);
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
  final FocusNode _nameFocusNode = FocusNode();

  /// Window-level shortcut scope:
  ///  * Ctrl+Enter submits the form — the same as tapping "Save & Complete
  ///    Sale" — returning to the sales screen which finishes the bill for
  ///    the next customer.
  ///  * Ctrl+W makes it a walk-in customer (same as tapping the Walk-in
  ///    mode chip): no customer data is saved for the sale.
  late final AppKeyboardScope _checkoutKeys = AppKeyboardScope(
    'checkout-complete',
    (event) {
      if (!mounted) return false;
      // Only while this checkout itself is the top-most page (so shortcuts
      // don't double-fire the sales screen's shortcut as well — its scope
      // sits below this one; this check plus the "top-most wins" LIFO order
      // keeps the two from racing).
      final route = ModalRoute.of(context);
      if (route != null && !route.isCurrent) return false;

      final noShiftAlt =
          !HardwareKeyboard.instance.isShiftPressed &&
          !HardwareKeyboard.instance.isAltPressed;

      final isCtrlEnter =
          AppKeyboardScope.didPress(
            event,
            LogicalKeyboardKey.enter,
            ctrl: true,
          ) ||
          AppKeyboardScope.didPress(
            event,
            LogicalKeyboardKey.numpadEnter,
            ctrl: true,
          );
      if (isCtrlEnter && noShiftAlt) {
        _submitCheckout();
        return true;
      }

      // Ctrl+W → walk-in customer.
      if (AppKeyboardScope.didPress(
            event,
            LogicalKeyboardKey.keyW,
            ctrl: true,
          ) &&
          noShiftAlt) {
        _setCheckoutMode('walk-in');
        return true;
      }

      return false;
    },
  );

  // Anchor + overlay for the customer-name suggestions so they float over the
  // fields below (like a real dropdown) instead of taking layout space and
  // pushing the form down / leaving a gap.
  final LayerLink _nameFieldLink = LayerLink();
  final OverlayPortalController _suggestionsPortal = OverlayPortalController();
  double _nameFieldWidth = 0;

  @override
  void initState() {
    super.initState();
    AppKeyboardScope.register(_checkoutKeys);

    // Focus the customer name as soon as the page opens so the sale can be
    // finished with the keyboard alone (name → Tab through fields → Ctrl+Enter).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final checkoutState = ref.read(checkoutProvider);
      if (!checkoutState.isWalkIn && !checkoutState.isTestBill) {
        _nameFocusNode.requestFocus();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final customers = await ref.read(databaseServiceProvider).getCustomers();
      ref.read(checkoutProvider.notifier).loadCustomers(customers);
      final fieldConfigs =
          await ref.read(databaseServiceProvider).getCustomerFieldConfigs();
      // Apply the whole saved map (including any user-added custom fields)
      // before the per-key fixes below.
      ref
          .read(customerFormProvider.notifier)
          .replaceAllFieldConfigs(fieldConfigs);
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
            // An empty name means a walk-in customer, so name can never block
            // the sale.
            isRequired: false,
          );
      ref
          .read(customerFormProvider.notifier)
          .updateFieldConfig(
            'address',
            title: fieldConfigs['address']?.title ?? 'Address',
            hintText: fieldConfigs['address']?.hintText ?? 'Enter address',
            validatorText:
                fieldConfigs['address']?.validatorText ?? 'Address is required',
            // Address is completely optional — never required.
            isShow: fieldConfigs['address']?.isShow ?? true,
            isRequired: false,
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
            // Phone is optional too — details just make it a saved customer.
            isShow: fieldConfigs['phoneNumber']?.isShow ?? true,
            isRequired: false,
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
    AppKeyboardScope.unregister(_checkoutKeys);
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    paidAmountController.dispose();
    discountController.dispose();
    for (final controller in _customControllers.values) {
      controller.dispose();
    }
    _customControllers.clear();
    _nameFocusNode.dispose();
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
      _clearCustomFields();
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
      _clearCustomFields();
    } else {
      // Customer mode
      ref.read(checkoutProvider.notifier).setCustomerMode();
      nameController.text = '';
      addressController.text = '';
      phoneController.text = '';
      ref.read(customerFormProvider.notifier).updateName('');
      ref.read(customerFormProvider.notifier).updateAddress('');
      ref.read(customerFormProvider.notifier).updatePhoneNumber('');
      _clearCustomFields();
    }
  }

  /// Customer data returned to the sales screen. An empty name means a
  /// walk-in customer (nothing is saved to the customer DB); any typed
  /// details (phone/address are optional) make it a regular saved customer.
  Map<String, dynamic> _buildCustomerData() {
    final checkoutState = ref.read(checkoutProvider);
    final isTestBill = checkoutState.isTestBill;
    final isWalkInMode = checkoutState.isWalkIn || isTestBill;
    final customerFormState = ref.read(customerFormProvider);

    // Only shown custom fields with a value are sent along; the sales screen
    // merges them into the saved customer record.
    final shownCustomFields = <String, dynamic>{
      for (final entry in customerFormState.fieldConfigs.entries)
        if (entry.key.startsWith('custom_') &&
            entry.value.isShow &&
            customerFormState.customValues[entry.key] != null)
          entry.key: customerFormState.customValues[entry.key],
    };

    if (isWalkInMode || nameController.text.trim().isEmpty) {
      // Walk-in / test bill: no customer record is saved.
      return {
        'name':
            nameController.text.trim().isNotEmpty
                ? nameController.text.trim()
                : (isTestBill ? 'TEST' : 'WALK-IN'),
        'address': null,
        'phoneNumber': null,
        'isWalkIn': !isTestBill,
        'isTestBill': isTestBill,
      };
    }

    return {
      'name': nameController.text.trim(),
      'address': addressController.text.trim(),
      'phoneNumber': phoneController.text.trim(),
      'customFields': shownCustomFields,
      'isWalkIn': false,
      'isTestBill': false,
    };
  }

  /// Shared submit logic: validate the form and pop back with the customer
  /// data. Used by the "Save & Complete Sale" button AND the Ctrl+Enter
  /// shortcut, so both paths behave identically.
  void _submitCheckout() {
    debugPrint('========== CHECKOUT: Save & Complete Sale ==========');

    if (!_formKey.currentState!.validate()) {
      debugPrint('ERROR: Form validation failed!');
      return;
    }

    if (!mounted) return;
    final currentSalesState = ref.read(salesProvider);
    final customerFormState = ref.read(customerFormProvider);
    final totalAfterDiscount =
        widget.totalAmount - (customerFormState.discount ?? widget.discount);

    if (!currentSalesState.isPaid &&
        currentSalesState.paidAmount > totalAfterDiscount) {
      AppFlushbar.error(context, message: 'Paid amount cannot exceed total');
      return;
    }

    final customerData = _buildCustomerData();
    debugPrint('Customer Data to Return: $customerData');
    Navigator.pop(context, customerData);
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
                  focusNode: _nameFocusNode,
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
          SizedBox(height: 4.spMin),
          mdText(
            text:
                isTestBill
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
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                            ),
                            SizedBox(width: 6.spMin),
                            smText(
                              text: customer.name,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
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
                          _applyCustomerCustomFields(customer);
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
      // Only digits and a dash are typable (e.g. "0300-1234567"); nothing else
      // reaches the field, and the total length is capped.
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
        LengthLimitingTextInputFormatter(16),
      ],
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
                if (value != null && value.isNotEmpty) {
                  // Allow an optional dash after the code (e.g. "0300-1234567").
                  final digitsOnly = value.replaceAll('-', '');
                  if (!RegExp(r'^[0-9]+(-[0-9]+)*$').hasMatch(value) ||
                      digitsOnly.length < 7 ||
                      digitsOnly.length > 15) {
                    return 'Enter a valid phone number (7-15 digits)';
                  }
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

  // ---- User-defined custom fields (Settings → Screen Management → Add Field) ----

  /// Controllers for the text-type custom fields, keyed by field key.
  final Map<String, TextEditingController> _customControllers = {};

  TextEditingController _customController(String key) {
    return _customControllers.putIfAbsent(
      key,
      () => TextEditingController(
        text:
            ref.read(customerFormProvider).customValues[key]?.toString() ?? '',
      ),
    );
  }

  /// Builds every visible custom field for the checkout form, in the order
  /// they were added in Settings.
  List<Widget> _buildCustomFields(CustomerFormState state, bool isWalkIn) {
    final widgets = <Widget>[];
    for (final entry in state.fieldConfigs.entries) {
      if (!entry.key.startsWith('custom_') || !entry.value.isShow) continue;
      widgets.add(_buildCustomField(entry.key, entry.value, state, isWalkIn));
      widgets.add(SizedBox(height: 24.spMin));
    }
    return widgets;
  }

  Widget _buildCustomField(
    String key,
    FieldConfig config,
    CustomerFormState state,
    bool isWalkIn,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorText =
        config.validatorText.isNotEmpty
            ? config.validatorText
            : '${config.title} is required';

    switch (config.widgetType) {
      case WidgetType.dropdown:
        final options = (config.options ?? const <String>[]).toList();
        final current = state.customValues[key]?.toString();
        return AppDropdown<String>(
          label: config.title,
          hintText: config.hintText,
          items: options,
          value: current != null && options.contains(current) ? current : null,
          filled: true,
          validator:
              config.isRequired && !isWalkIn
                  ? (value) =>
                      (value == null || value.isEmpty) ? errorText : null
                  : null,
          onChanged:
              isWalkIn
                  ? null
                  : (value) => ref
                      .read(customerFormProvider.notifier)
                      .updateCustomField(key, value),
        );
      case WidgetType.checkbox:
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(config.title, style: TextStyle(fontSize: 14.spMin)),
          subtitle:
              config.hintText.isNotEmpty
                  ? Text(
                    config.hintText,
                    style: TextStyle(fontSize: 11.spMin, color: Colors.grey),
                  )
                  : null,
          value: state.customValues[key] == true,
          onChanged:
              isWalkIn
                  ? null
                  : (value) => ref
                      .read(customerFormProvider.notifier)
                      .updateCustomField(key, value ?? false),
        );
      case WidgetType.imagePicker:
      case WidgetType.textField:
        return CustomTextField(
          controller: _customController(key),
          label: config.title,
          hintText: config.hintText,
          filled: true,
          enabled: !isWalkIn,
          readOnly: isWalkIn,
          prefixIcon: AppIcon(
            defaultIcon: Icons.label_outline,
            win11IconPath: ImageAssets.win11Label,
            size: 20.spMin,
            color: isDark ? Colors.white : AppColors.lIconColor,
          ),
          validator:
              config.isRequired && !isWalkIn
                  ? (value) =>
                      (value == null || value.trim().isEmpty) ? errorText : null
                  : null,
          onChange:
              isWalkIn
                  ? null
                  : (value) {
                    ref
                        .read(customerFormProvider.notifier)
                        .updateCustomField(key, value ?? '');
                    return null;
                  },
        );
    }
  }

  /// Fills the custom-field widgets from an existing customer record when it
  /// is picked from the suggestions list.
  void _applyCustomerCustomFields(Customer customer) {
    final notifier = ref.read(customerFormProvider.notifier);
    for (final entry in customer.customFields.entries) {
      _customControllers[entry.key]?.text = entry.value?.toString() ?? '';
      notifier.updateCustomField(entry.key, entry.value);
    }
  }

  /// Clears every custom field (used when switching walk-in / test modes).
  void _clearCustomFields() {
    for (final controller in _customControllers.values) {
      controller.clear();
    }
    ref.read(customerFormProvider.notifier).updateCustomValues(const {});
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
        SizedBox(height: 8.spMin),
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
                  SizedBox(height: 4.spMin),
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
          SizedBox(height: 16.spMin),
        ],
        if (customerFormState.fieldConfigs['address']!.isShow) ...[
          _buildAddressField(customerFormState, isWalkIn),
          SizedBox(height: 16.spMin),
        ],
        if (customerFormState.fieldConfigs['phoneNumber']!.isShow) ...[
          _buildPhoneField(customerFormState, isWalkIn),
          SizedBox(height: 24.spMin),
        ],
        // User-defined custom fields (Settings → Add Field).
        ..._buildCustomFields(customerFormState, isWalkIn),
        if (customerFormState.fieldConfigs['paymentStatus']!.isShow) ...[
          _buildPaymentStatusField(customerFormState, salesState),
          SizedBox(height: 24.spMin),
        ],
        if (customerFormState.fieldConfigs['paymentMethod']!.isShow) ...[
          _buildPaymentMethodField(customerFormState, salesState),
          SizedBox(height: 24.spMin),
        ],
        if (customerFormState.fieldConfigs['paidAmount']!.isShow &&
            !salesState.isPaid) ...[
          _buildPaidAmountField(
            customerFormState,
            salesState,
            totalAfterDiscount,
          ),
          SizedBox(height: 32.spMin),
        ],
        // Discount is the LAST field, right above the Save button.
        if (customerFormState.fieldConfigs['discount']!.isShow) ...[
          _buildDiscountField(customerFormState),
          SizedBox(height: 24.spMin),
        ],
        AppButton().primaryButton(
          text: isTestBill ? "Generate Test Bill" : "Save & Complete Sale",
          onPressed: _submitCheckout,
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
                SizedBox(width: 16.spMin),
              if (customerFormState.fieldConfigs['phoneNumber']!.isShow)
                Expanded(child: _buildPhoneField(customerFormState, isWalkIn)),
            ],
          ),
        SizedBox(height: 16.spMin),
        if (customerFormState.fieldConfigs['address']!.isShow) ...[
          _buildAddressField(customerFormState, isWalkIn),
          SizedBox(height: 24.spMin),
        ],
        // User-defined custom fields (Settings → Add Field).
        ..._buildCustomFields(customerFormState, isWalkIn),
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
                SizedBox(width: 16.spMin),
              if (customerFormState.fieldConfigs['paymentMethod']!.isShow)
                Expanded(
                  child: _buildPaymentMethodField(
                    customerFormState,
                    salesState,
                  ),
                ),
            ],
          ),
        SizedBox(height: 24.spMin),
        if (customerFormState.fieldConfigs['paidAmount']!.isShow &&
            !salesState.isPaid) ...[
          _buildPaidAmountField(
            customerFormState,
            salesState,
            totalAfterDiscount,
          ),
          SizedBox(height: 32.spMin),
        ],
        // Discount is the LAST field, right above the Save button.
        if (customerFormState.fieldConfigs['discount']!.isShow) ...[
          _buildDiscountField(customerFormState),
          SizedBox(height: 24.spMin),
        ],
        AppButton().primaryButton(
          text: isTestBill ? "Generate Test Bill" : "Save & Complete Sale",
          onPressed: _submitCheckout,
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
                SizedBox(width: 4.spMin),
                smText(
                  text:
                      checkoutState.isTestBill
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
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'customer',
                    child: Row(
                      children: [
                        Icon(TablerIcons.user, size: 18.spMin),
                        SizedBox(width: 8.spMin),
                        const Text('Customer'),
                        if (!checkoutState.isWalkIn &&
                            !checkoutState.isTestBill)
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: Icon(
                              Icons.check,
                              size: 16.spMin,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'walk-in',
                    child: Row(
                      children: [
                        Icon(TablerIcons.walk, size: 18.spMin),
                        SizedBox(width: 8.spMin),
                        const Text('Walk-in'),
                        if (checkoutState.isWalkIn)
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: Icon(
                              Icons.check,
                              size: 16.spMin,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'test-bill',
                    child: Row(
                      children: [
                        Icon(TablerIcons.test_pipe, size: 18.spMin),
                        SizedBox(width: 8.spMin),
                        const Text('Test Bill'),
                        if (checkoutState.isTestBill)
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: Icon(
                              Icons.check,
                              size: 16.spMin,
                              color: Colors.green,
                            ),
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
