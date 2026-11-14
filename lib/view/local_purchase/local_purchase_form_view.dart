import '../../utils/currency_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../models/local_purchase_model.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_button.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/text_field_widget.dart';
import '../../utils/app_sizes.dart';
import '../../view_models/providers/local_purchase_provider.dart';
import '../../view_models/providers/settings_provider.dart';
import '../../view_models/services/database/database_services.dart';
import '../../view_models/services/keyboard/app_keyboard_service.dart';

class LocalPurchaseFormView extends ConsumerStatefulWidget {
  final LocalPurchaseAgreement? agreement;

  const LocalPurchaseFormView({super.key, this.agreement});

  @override
  ConsumerState<LocalPurchaseFormView> createState() =>
      _LocalPurchaseFormViewState();
}

class _LocalPurchaseFormViewState extends ConsumerState<LocalPurchaseFormView> {
  final _formKey = GlobalKey<FormState>();

  /// Ctrl+S saves, Ctrl+I adds an item row — handled by the window-level
  /// keyboard dispatcher (see [AppKeyboardScope]) — focus-independent.
  late final AppKeyboardScope _keys = AppKeyboardScope('purchase-form', (
    event,
  ) {
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyS, ctrl: true)) {
      _save();
      return true;
    }
    // Ctrl+I — add another item row.
    if (AppKeyboardScope.didPress(event, LogicalKeyboardKey.keyI, ctrl: true)) {
      _addItemRow();
      return true;
    }
    return false;
  });

  late final TextEditingController _sellerNameController;
  late final TextEditingController _sellerPhoneController;
  late final TextEditingController _sellerIdCardController;
  late final TextEditingController _sellerAddressController;
  late final TextEditingController _sellerSignatureController;
  late final TextEditingController _ownerSignatureController;
  late final TextEditingController _notesController;

  String _paymentType = 'Cash';
  final List<LocalPurchaseItem> _items = [];
  final List<TextEditingController> _itemNameControllers = [];
  final List<TextEditingController> _itemQtyControllers = [];
  final List<TextEditingController> _itemPriceControllers = [];

  /// Payment type choices from Settings (Bill Settings → Payment Methods).
  /// Defaults until the saved list loads.
  List<String> _paymentTypes = HiveService.defaultPaymentMethods;

  bool get _isEditing => widget.agreement != null;

  @override
  void initState() {
    super.initState();
    final a = widget.agreement;

    _sellerNameController = TextEditingController(text: a?.sellerName ?? '');
    _sellerPhoneController = TextEditingController(text: a?.sellerPhone ?? '');
    _sellerIdCardController = TextEditingController(
      text: a?.sellerIdCard ?? '',
    );
    _sellerAddressController = TextEditingController(
      text: a?.sellerAddress ?? '',
    );
    _sellerSignatureController = TextEditingController(
      text: a?.sellerSignature ?? '',
    );
    _ownerSignatureController = TextEditingController(
      text: a?.ownerSignature ?? '',
    );
    _notesController = TextEditingController(text: a?.notes ?? '');

    if (a != null) {
      _paymentType = a.paymentType;
      for (final item in a.items) {
        _addItemFromExisting(item);
      }
    } else {
      _addEmptyItem();
    }
    AppKeyboardScope.register(_keys);
    _loadPaymentTypes();
  }

  /// Loads the payment choices saved in Settings (Bill Settings → Payment
  /// Methods) so purchase forms follow the same list as checkout. When
  /// editing a record whose type was removed from the list, it is kept at
  /// the front so the saved choice still shows.
  Future<void> _loadPaymentTypes() async {
    try {
      final methods = await DatabaseService().getPaymentMethods();
      if (!mounted) return;
      if (!methods.contains(_paymentType)) {
        methods.insert(0, _paymentType);
      }
      setState(() => _paymentTypes = methods);
    } catch (e) {
      debugPrint('Failed to load payment methods: $e');
    }
  }

  /// Adds a new blank item row (Ctrl+I / "Add Item" button).
  void _addItemRow() {
    setState(_addEmptyItem);
  }

  void _addItemFromExisting(LocalPurchaseItem item) {
    _items.add(item);
    _itemNameControllers.add(TextEditingController(text: item.name));
    _itemQtyControllers.add(
      TextEditingController(text: item.quantity.toString()),
    );
    _itemPriceControllers.add(
      TextEditingController(text: item.unitPrice.toStringAsFixed(0)),
    );
  }

  void _addEmptyItem() {
    _items.add(
      LocalPurchaseItem(
        id: const Uuid().v4(),
        name: '',
        quantity: 1,
        unitPrice: 0,
      ),
    );
    _itemNameControllers.add(TextEditingController());
    _itemQtyControllers.add(TextEditingController(text: '1'));
    _itemPriceControllers.add(TextEditingController());
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      AppFlushbar.info(context, message: 'At least one item is required.');
      return;
    }
    setState(() {
      _items.removeAt(index);
      _itemNameControllers[index].dispose();
      _itemQtyControllers[index].dispose();
      _itemPriceControllers[index].dispose();
      _itemNameControllers.removeAt(index);
      _itemQtyControllers.removeAt(index);
      _itemPriceControllers.removeAt(index);
    });
  }

  double get _totalAmount {
    double total = 0;
    for (int i = 0; i < _items.length; i++) {
      final qty = int.tryParse(_itemQtyControllers[i].text) ?? 0;
      final price = double.tryParse(_itemPriceControllers[i].text) ?? 0;
      total += qty * price;
    }
    return total;
  }

  List<LocalPurchaseItem> _buildItems() {
    final result = <LocalPurchaseItem>[];
    for (int i = 0; i < _items.length; i++) {
      final name = _itemNameControllers[i].text.trim();
      final qty = int.tryParse(_itemQtyControllers[i].text) ?? 1;
      final price = double.tryParse(_itemPriceControllers[i].text) ?? 0;
      if (name.isNotEmpty && qty > 0 && price > 0) {
        result.add(
          LocalPurchaseItem(
            id: _items[i].id,
            name: name,
            quantity: qty,
            unitPrice: price,
          ),
        );
      }
    }
    return result;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final items = _buildItems();
    if (items.isEmpty) {
      AppFlushbar.info(context, message: 'Please add at least one valid item.');
      return;
    }

    final agreement = LocalPurchaseAgreement(
      id: widget.agreement?.id ?? const Uuid().v4(),
      dateTime: widget.agreement?.dateTime ?? DateTime.now(),
      sellerName: _sellerNameController.text.trim(),
      sellerPhone:
          _sellerPhoneController.text.trim().isEmpty
              ? null
              : _sellerPhoneController.text.trim(),
      sellerIdCard:
          _sellerIdCardController.text.trim().isEmpty
              ? null
              : _sellerIdCardController.text.trim(),
      sellerAddress:
          _sellerAddressController.text.trim().isEmpty
              ? null
              : _sellerAddressController.text.trim(),
      sellerSignature:
          _sellerSignatureController.text.trim().isEmpty
              ? null
              : _sellerSignatureController.text.trim(),
      ownerSignature:
          _ownerSignatureController.text.trim().isEmpty
              ? null
              : _ownerSignatureController.text.trim(),
      paymentType: _paymentType,
      items: items,
      totalAmount: _totalAmount,
      // Terms are configured once in Settings → Purchase Agreement and are not
      // edited on this form. When editing an existing agreement, keep the terms
      // it was originally signed with.
      termsAndConditions:
          (widget.agreement?.termsAndConditions.isNotEmpty ?? false)
              ? widget.agreement!.termsAndConditions
              : ref.read(settingsProvider).purchaseTerms,
      notes:
          _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
    );

    await ref.read(localPurchaseProvider.notifier).saveAgreement(agreement);

    if (mounted) {
      AppFlushbar.success(
        context,
        message:
            _isEditing
                ? 'Agreement updated successfully.'
                : 'Agreement saved successfully.',
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerIdCardController.dispose();
    _sellerAddressController.dispose();
    _sellerSignatureController.dispose();
    _ownerSignatureController.dispose();
    _notesController.dispose();
    for (final c in _itemNameControllers) {
      c.dispose();
    }
    for (final c in _itemQtyControllers) {
      c.dispose();
    }
    for (final c in _itemPriceControllers) {
      c.dispose();
    }
    AppKeyboardScope.unregister(_keys);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppSizes.isDesktop(context);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: _isEditing ? 'Edit Agreement' : 'New Purchase Agreement',
        context: context,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          // Keep the top tight — the AppBar already provides breathing room.
          padding: EdgeInsets.only(
            left: isDesktop ? 24.w : 16.w,
            right: isDesktop ? 24.w : 16.w,
            top: 8.h,
            bottom: 24.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Seller Information'),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _sellerNameController,
                label: 'Seller Name *',
                hint: 'Enter seller full name',
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Seller name is required'
                            : null,
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _sellerPhoneController,
                      label: 'Phone Number',
                      hint: '03XX-XXXXXXX',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField(
                      controller: _sellerIdCardController,
                      label: 'ID Card Number',
                      hint: 'CNIC / ID number',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _sellerAddressController,
                label: 'Address',
                hint: 'Seller address',
                maxLines: 2,
              ),
              SizedBox(height: 24.h),

              // Section title and the "Add Item" action share one row.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _sectionTitle('Items Purchased')),
                  SizedBox(width: 8.w),
                  Tooltip(
                    message: 'Add item (Ctrl+I)',
                    child: AppButton().primaryButton(
                      text: 'Add Item',
                      onPressed: _addItemRow,
                      width: 118.spMin,
                      height: 34.spMin,
                      fontSize: 12.spMin,
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ..._buildItemFields(),
              SizedBox(height: 12.h),
              _buildTotalRow(),
              SizedBox(height: 24.h),

              _sectionTitle('Payment & Signatures'),
              SizedBox(height: 12.h),
              AppDropdown<String>(
                label: 'Payment Type',
                hintText: 'Select payment type',
                items: _paymentTypes,
                value: _paymentType,
                onChanged: (v) {
                  if (v != null) setState(() => _paymentType = v);
                },
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _sellerSignatureController,
                      label: 'Seller Signature (type name)',
                      hint: 'Seller name as signature',
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _buildTextField(
                      controller: _ownerSignatureController,
                      label: 'Owner Signature (type name)',
                      hint: 'Owner name as signature',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Terms & conditions are NOT edited here — they are set once in
              // Settings → Purchase Agreement and applied automatically.
              _sectionTitle('Notes'),
              SizedBox(height: 12.h),
              _buildTextField(
                controller: _notesController,
                label: 'Additional Notes',
                hint: 'Any extra notes...',
                maxLines: 3,
              ),
              SizedBox(height: 32.h),

              AppButton().primaryButton(
                text: 'Save Agreement',
                onPressed: _save,
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.spMin,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: hint,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
    );
  }

  List<Widget> _buildItemFields() {
    return List.generate(_items.length, (index) {
      return Card(
        margin: EdgeInsets.only(bottom: 8.h),
        child: Padding(
          padding: EdgeInsets.all(12.spMin),
          child: Column(
            children: [
              Row(
                // Bottom-align so the delete icon centres on the input box
                // rather than on the label + box.
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      controller: _itemNameControllers[index],
                      label: 'Item Name',
                      hintText: 'Item name',
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: CustomTextField(
                      controller: _itemQtyControllers[index],
                      label: 'Qty',
                      hintText: '1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _itemPriceControllers[index],
                      label: 'Unit Price',
                      hintText: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(
                    width: 40.spMin,
                    height: 46.spMin,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      iconSize: 20.spMin,
                      tooltip: 'Remove item',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _removeItem(index)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTotalRow() {
    return Container(
      padding: EdgeInsets.all(12.spMin),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.bold),
          ),
          Text(
            '${CurrencyService.symbol}${_totalAmount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16.spMin,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
