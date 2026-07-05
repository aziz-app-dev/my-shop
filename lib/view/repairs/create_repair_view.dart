import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:uuid/uuid.dart';

import '../../models/coustomer_model.dart';
import '../../models/items_model.dart';
import '../../models/repair_model.dart';
import '../../res/colors/app_color.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_button.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/text_field_widget.dart';
import '../../utils/image_picker_helper.dart';
import '../../view_models/providers/customer_prvider.dart';
import '../../view_models/providers/product_view.dart';
import '../../view_models/providers/repair_provider.dart';

/// Create / edit a repair job. Rewritten from scratch with a dead-simple,
/// bulletproof layout: a Scaffold whose body is a single ListView holding every
/// field AND the submit button at the end. No bottomNavigationBar, no nested
/// LayoutBuilder/Align/IntrinsicHeight — those caused earlier zero-height
/// collapses where only the button showed.
class CreateRepairView extends ConsumerStatefulWidget {
  final Repair? existing;
  const CreateRepairView({super.key, this.existing});

  @override
  ConsumerState<CreateRepairView> createState() => _CreateRepairViewState();
}

class _CreateRepairViewState extends ConsumerState<CreateRepairView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _serialController;
  late final TextEditingController _problemController;
  late final TextEditingController _accessoriesController;
  late final TextEditingController _estCostController;
  late final TextEditingController _advanceController;

  static const List<String> _deviceTypes = [
    'Laptop',
    'Desktop',
    'Phone',
    'Tablet',
    'Printer',
    'Monitor',
    'Other',
  ];

  String? _deviceType;
  String? _customerId;
  String? _imagePath;
  late DateTime _receivedDate;
  DateTime? _expectedDate;

  // Parts/services added to this repair.
  final List<RepairItem> _items = [];

  bool get _isEditing => widget.existing != null;

  double get _itemsTotal =>
      _items.fold(0.0, (sum, i) => sum + i.total);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customersProvider.notifier).fetchData();
    });

    final r = widget.existing;
    _nameController = TextEditingController(text: r?.clientName ?? '');
    _phoneController = TextEditingController(text: r?.clientPhone ?? '');
    _brandController = TextEditingController(text: r?.brand ?? '');
    _modelController = TextEditingController(text: r?.model ?? '');
    _serialController = TextEditingController(text: r?.serialNumber ?? '');
    _problemController = TextEditingController(text: r?.problem ?? '');
    _accessoriesController = TextEditingController(text: r?.accessories ?? '');
    _estCostController = TextEditingController(
      text: (r != null && r.estimatedCost > 0)
          ? r.estimatedCost.toStringAsFixed(0)
          : '',
    );
    _advanceController = TextEditingController(
      text: (r != null && r.advancePaid > 0)
          ? r.advancePaid.toStringAsFixed(0)
          : '',
    );
    _deviceType = (r?.deviceType.isNotEmpty ?? false) ? r!.deviceType : null;
    _customerId = r?.customerId;
    _imagePath = r?.imageUrl;
    _receivedDate = r?.receivedDate ?? DateTime.now();
    _expectedDate = r?.expectedDate;
    if (r != null) _items.addAll(r.items);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _problemController.dispose();
    _accessoriesController.dispose();
    _estCostController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider).allCustomers;

    return Scaffold(
      appBar: AppBarWidget.customAppBar(title: 'Repair', context: context),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.spMin, 16.spMin, 16.spMin, 24.spMin),
          children: [
            _label('Client'),
            _customerPicker(customers),
            SizedBox(height: 12.spMin),
            CustomTextField(
              controller: _nameController,
              label: 'Client Name',
              hintText: 'e.g. Ahmed Khan',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Client name is required'
                  : null,
            ),
            SizedBox(height: 12.spMin),
            CustomTextField(
              controller: _phoneController,
              label: 'Phone',
              hintText: 'e.g. 0300xxxxxxx',
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 20.spMin),

            _label('Device'),
            _deviceTypeDropdown(),
            SizedBox(height: 12.spMin),
            CustomTextField(
              controller: _brandController,
              label: 'Brand',
              hintText: 'e.g. Dell, HP',
            ),
            SizedBox(height: 12.spMin),
            CustomTextField(
              controller: _modelController,
              label: 'Model',
              hintText: 'e.g. Latitude 5400',
            ),
            SizedBox(height: 12.spMin),
            CustomTextField(
              controller: _serialController,
              label: 'Serial Number',
              hintText: 'Optional',
            ),
            SizedBox(height: 12.spMin),
            _photoPicker(),
            SizedBox(height: 20.spMin),

            _label('Problem & Accessories'),
            CustomTextField(
              controller: _problemController,
              label: 'Reported Problem',
              hintText: 'e.g. Not turning on, screen cracked',
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Describe the problem'
                  : null,
            ),
            SizedBox(height: 12.spMin),
            CustomTextField(
              controller: _accessoriesController,
              label: 'Accessories Received',
              hintText: 'e.g. Charger, bag, mouse',
              maxLines: 2,
            ),
            SizedBox(height: 20.spMin),

            _itemsSection(),
            SizedBox(height: 20.spMin),

            _label('Cost & Dates'),
            CustomTextField(
              controller: _estCostController,
              label: 'Estimated Cost',
              hintText: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
            ),
            SizedBox(height: 12.spMin),
            CustomTextField(
              controller: _advanceController,
              label: 'Advance Paid',
              hintText: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
              ],
            ),
            SizedBox(height: 12.spMin),
            _dateField(
              label: 'Received Date',
              value: _receivedDate,
              onPick: (d) => setState(() => _receivedDate = d),
            ),
            SizedBox(height: 12.spMin),
            _dateField(
              label: 'Expected Date',
              value: _expectedDate,
              onPick: (d) => setState(() => _expectedDate = d),
              allowClear: true,
              onClear: () => setState(() => _expectedDate = null),
            ),
            SizedBox(height: 24.spMin),

            // Submit button lives at the END of the list — always visible when
            // scrolled to, no separate bottom bar to collapse the body.
            AppButton().primaryButton(
              text: _isEditing ? 'Save Changes' : 'Add Repair',
              onPressed: _save,
              height: 48.spMin,
              borderRadius: 12,
            ),
          ],
        ),
      ),
    );
  }

  // ---- pieces -----------------------------------------------------------

  Widget _label(String text) => Padding(
        padding: EdgeInsets.only(bottom: 8.spMin),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.spMin,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );

  // ---- Repair items (parts/services) -----------------------------------

  Widget _itemsSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _label('Items / Parts Used'),
            TextButton.icon(
              onPressed: _showAddItemSheet,
              icon: Icon(TablerIcons.plus, size: 16.spMin),
              label: Text('Add Item', style: TextStyle(fontSize: 12.spMin)),
            ),
          ],
        ),
        if (_items.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.spMin),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.spMin),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'No items added. Tap "Add Item" to add parts or services.',
              style: TextStyle(fontSize: 12.spMin, color: Colors.grey[600]),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.spMin),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ...List.generate(_items.length, (i) {
                  final item = _items[i];
                  return Container(
                    color: i.isOdd
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.03)
                            : Colors.black.withValues(alpha: 0.02))
                        : null,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.spMin,
                      vertical: 8.spMin,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 12.spMin,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.quantity} × Rs ${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11.spMin,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Rs ${item.total.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12.spMin,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4.spMin),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() => _items.removeAt(i));
                            _syncEstimatedCostToItems();
                          },
                          icon: Icon(
                            TablerIcons.trash,
                            size: 16.spMin,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.spMin,
                    vertical: 10.spMin,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items Total',
                        style: TextStyle(
                          fontSize: 13.spMin,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rs ${_itemsTotal.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14.spMin,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Keep the estimated-cost field in sync with the items total (items sum
  /// into the cost, per the chosen behaviour).
  void _syncEstimatedCostToItems() {
    _estCostController.text = _itemsTotal.toStringAsFixed(0);
  }

  void _showAddItemSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.spMin)),
      ),
      builder: (_) => _AddRepairItemSheet(
        onAdd: (item) {
          setState(() => _items.add(item));
          _syncEstimatedCostToItems();
        },
      ),
    );
  }

  Widget _customerPicker(List<Customer> customers) {
    // De-duplicate ids so AppDropdown never gets two items with the same value.
    final seen = <String>{};
    final unique = <Customer>[];
    for (final c in customers) {
      if (c.id.isNotEmpty && seen.add(c.id)) unique.add(c);
    }
    // Keep the current selection valid.
    final value =
        (_customerId != null && seen.contains(_customerId)) ? _customerId : null;

    return AppDropdown<String?>(
      label: 'Pick Existing Client (optional)',
      hintText: 'Select a client or type below',
      isExpanded: true,
      value: value,
      items: <String?>[null, ...unique.map((c) => c.id)],
      displayItems: <String>[
        'New / walk-in client',
        ...unique.map(
          (c) => c.phoneNumber.isNotEmpty
              ? '${c.name} (${c.phoneNumber})'
              : c.name,
        ),
      ],
      onChanged: (id) {
        setState(() {
          _customerId = id;
          if (id != null) {
            final c = unique.firstWhere(
              (e) => e.id == id,
              orElse: () => Customer(id: '', name: ''),
            );
            if (c.id.isNotEmpty) {
              _nameController.text = c.name;
              _phoneController.text = c.phoneNumber;
            }
          }
        });
      },
    );
  }

  Widget _deviceTypeDropdown() {
    return AppDropdown<String>(
      label: 'Device Type',
      hintText: 'Select type',
      isExpanded: true,
      value: _deviceType,
      items: _deviceTypes,
      onChanged: (v) => setState(() => _deviceType = v),
    );
  }

  Widget _photoPicker() {
    final hasImage = _imagePath != null &&
        _imagePath!.isNotEmpty &&
        File(_imagePath!).existsSync();
    return Row(
      children: [
        Container(
          width: 64.spMin,
          height: 64.spMin,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.spMin),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasImage
              ? Image.file(File(_imagePath!), fit: BoxFit.cover)
              : Icon(TablerIcons.camera, color: AppColors.primary),
        ),
        SizedBox(width: 12.spMin),
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(TablerIcons.photo),
          label: Text(
            hasImage ? 'Change photo' : 'Add item photo',
            style: TextStyle(fontSize: 12.spMin),
          ),
        ),
        if (hasImage)
          IconButton(
            tooltip: 'Remove photo',
            onPressed: () => setState(() => _imagePath = null),
            icon: Icon(TablerIcons.x, size: 16.spMin, color: AppColors.error),
          ),
      ],
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
    bool allowClear = false,
    VoidCallback? onClear,
  }) {
    final text = value == null
        ? 'Not set'
        : '${value.day}/${value.month}/${value.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.spMin,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 6.spMin),
        InkWell(
          borderRadius: BorderRadius.circular(8.spMin),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2015),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding:
                EdgeInsets.symmetric(horizontal: 12.spMin, vertical: 12.spMin),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.spMin),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              children: [
                Icon(TablerIcons.calendar, size: 16.spMin),
                SizedBox(width: 8.spMin),
                Expanded(
                  child: Text(text, style: TextStyle(fontSize: 12.spMin)),
                ),
                if (allowClear && value != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.clear, size: 16.spMin),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final file = await ImagePickerHelper.pickImageFromGallery();
    if (file != null) setState(() => _imagePath = file.path);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final estCost = double.tryParse(_estCostController.text.trim()) ?? 0.0;
    final advance = double.tryParse(_advanceController.text.trim()) ?? 0.0;
    final now = DateTime.now();

    final repair = (widget.existing ??
            Repair(
              id: const Uuid().v4(),
              clientName: '',
              receivedDate: now,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      customerId: _customerId,
      clientName: _nameController.text.trim(),
      clientPhone: _phoneController.text.trim(),
      deviceType: _deviceType ?? '',
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      serialNumber: _serialController.text.trim(),
      imageUrl: _imagePath,
      problem: _problemController.text.trim(),
      accessories: _accessoriesController.text.trim(),
      items: List<RepairItem>.from(_items),
      estimatedCost: estCost,
      advancePaid: advance,
      receivedDate: _receivedDate,
      expectedDate: _expectedDate,
      updatedAt: now,
    );

    final notifier = ref.read(repairProvider.notifier);
    if (_isEditing) {
      await notifier.updateRepair(repair);
    } else {
      await notifier.addRepair(repair);
    }

    if (!mounted) return;
    Navigator.pop(context);
    AppFlushbar.success(
      context,
      message: _isEditing ? 'Repair updated' : 'Repair added',
    );
  }
}

/// Bottom sheet to add a repair item — either pick an inventory product or type
/// a custom line item. Returns the item via [onAdd].
class _AddRepairItemSheet extends ConsumerStatefulWidget {
  final ValueChanged<RepairItem> onAdd;
  const _AddRepairItemSheet({required this.onAdd});

  @override
  ConsumerState<_AddRepairItemSheet> createState() =>
      _AddRepairItemSheetState();
}

class _AddRepairItemSheetState extends ConsumerState<_AddRepairItemSheet> {
  bool _custom = false; // false = pick from inventory, true = type custom
  Product? _selectedProduct;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    // If there are no inventory products, start in custom mode so the user can
    // add a new item straight away.
    final products = ref.read(productsNotifierProvider).asData?.value;
    if (products == null || products.isEmpty) _custom = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsNotifierProvider);
    final products = productsAsync.asData?.value ?? const <Product>[];

    return Padding(
      padding: EdgeInsets.only(
        left: 16.spMin,
        right: 16.spMin,
        top: 16.spMin,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.spMin,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TablerIcons.package, color: AppColors.primary),
              SizedBox(width: 8.spMin),
              Text(
                'Add Item',
                style: TextStyle(
                  fontSize: 15.spMin,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 8.spMin),
          // Toggle: inventory vs custom. Reset the fields on switch so a
          // stale product name/price/id doesn't carry over.
          Row(
            children: [
              _modeChip('From Inventory', !_custom, () {
                setState(() {
                  _custom = false;
                  _selectedProduct = null;
                  _nameController.clear();
                  _priceController.clear();
                });
              }),
              SizedBox(width: 8.spMin),
              _modeChip('Custom Item', _custom, () {
                setState(() {
                  _custom = true;
                  _selectedProduct = null;
                  _nameController.clear();
                  _priceController.clear();
                });
              }),
            ],
          ),
          SizedBox(height: 16.spMin),

          if (!_custom) ...[
            // Inventory product dropdown
            AppDropdown<Product?>(
              label: 'Product',
              hintText: products.isEmpty
                  ? 'No products available'
                  : 'Select a product',
              isExpanded: true,
              value: _selectedProduct,
              items: <Product?>[...products],
              displayItems: [
                for (final p in products)
                  '${p.name} (Rs ${p.price.toStringAsFixed(0)})',
              ],
              onChanged: (p) {
                setState(() {
                  _selectedProduct = p;
                  if (p != null) {
                    _nameController.text = p.name;
                    _priceController.text = p.price.toStringAsFixed(0);
                  }
                });
              },
            ),
            SizedBox(height: 12.spMin),
          ] else ...[
            CustomTextField(
              controller: _nameController,
              label: 'Item Name',
              hintText: 'e.g. Screen replacement, Labor',
            ),
            SizedBox(height: 12.spMin),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _priceController,
                  label: 'Price',
                  hintText: '0',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                ),
              ),
              SizedBox(width: 12.spMin),
              // Quantity stepper
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qty',
                    style: TextStyle(
                      fontSize: 12.spMin,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 6.spMin),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.spMin),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            if (_qty > 1) setState(() => _qty--);
                          },
                          icon: Icon(Icons.remove, size: 16.spMin),
                        ),
                        Text('$_qty', style: TextStyle(fontSize: 13.spMin)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(() => _qty++),
                          icon: Icon(Icons.add, size: 16.spMin),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.spMin),
          AppButton().primaryButton(
            text: 'Add Item',
            height: 46.spMin,
            borderRadius: 12,
            onPressed: _add,
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8.spMin),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.spMin),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.spMin),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.spMin,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? AppColors.primary : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  void _add() {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    if (name.isEmpty) {
      AppFlushbar.warning(context, message: 'Enter an item name');
      return;
    }
    widget.onAdd(
      RepairItem(
        productId: (!_custom && _selectedProduct != null)
            ? _selectedProduct!.id
            : '',
        name: name,
        price: price,
        quantity: _qty,
      ),
    );
    Navigator.pop(context);
  }
}
