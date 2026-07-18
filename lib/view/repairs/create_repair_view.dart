import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:uuid/uuid.dart';

import '../../models/brand_model.dart';
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
import '../brands/brand_management_view.dart' show brandsProvider;
import '../home/rapper.dart';
import '../widgets/cached_image_widget.dart';

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

  // Focus nodes so Enter/Next jumps between fields in order.
  final _nameNode = FocusNode();
  final _phoneNode = FocusNode();
  final _brandNode = FocusNode();
  final _modelNode = FocusNode();
  final _serialNode = FocusNode();
  final _problemNode = FocusNode();
  final _accessoriesNode = FocusNode();
  final _estCostNode = FocusNode();
  final _advanceNode = FocusNode();

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

  /// Customer mode. Walk-in = collect nothing (no linked customer). Registered
  /// = pick/search an existing customer in the name field.
  bool _isWalkIn = false;

  /// Whether the customer-search suggestions are currently shown.
  bool _showSuggestions = false;

  /// Whether the brand-search suggestions are currently shown.
  bool _showBrandSuggestions = false;

  /// Height of one suggestion row; the dropdown shows 4 then scrolls.
  static const double _suggestionRowH = 54;

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
    // An existing repair with no linked customer and no real name is a walk-in.
    final name = r?.clientName.trim() ?? '';
    _isWalkIn = r != null &&
        r.customerId == null &&
        (name.isEmpty || name.toLowerCase() == 'walk-in');
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
    _nameNode.dispose();
    _phoneNode.dispose();
    _brandNode.dispose();
    _modelNode.dispose();
    _serialNode.dispose();
    _problemNode.dispose();
    _accessoriesNode.dispose();
    _estCostNode.dispose();
    _advanceNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: _isEditing ? 'Edit Repair' : 'New Repair',
        context: context,
      ),
      body: Form(
        key: _formKey,
        // Full-width section cards (settings-style). Fields stack on mobile and
        // pair two-per-row on tablet/desktop; insets grow with the breakpoint.
        child: ResponsiveWrapper(
          mobile: _buildForm(twoCol: false, hPad: 16),
          tablet: _buildForm(twoCol: true, hPad: 24),
          desktop: _buildForm(twoCol: true, hPad: 40),
        ),
      ),
    );
  }

  void _focus(FocusNode node) => FocusScope.of(context).requestFocus(node);

  Widget _buildForm({required bool twoCol, required double hPad}) {
    final customers = ref.watch(customersProvider).allCustomers;
    final brands = ref.watch(brandsProvider).asData?.value ?? const <Brand>[];
    return ListView(
      // Horizontal insets grow with the breakpoint (like add_product /
      // edit_bill); vertical rhythm uses .spMin per the project's sizing rule.
      padding: EdgeInsets.symmetric(horizontal: hPad.w, vertical: 16.spMin),
      children: _formChildren(customers, brands, twoCol),
    );
  }

  List<Widget> _formChildren(
    List<Customer> customers,
    List<Brand> brands,
    bool twoCol,
  ) {
    Widget gap([double h = 12]) => SizedBox(height: h.spMin);

    // Always place two fields side by side in a row.
    Widget row2(Widget a, Widget b) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            SizedBox(width: 16.spMin),
            Expanded(child: b),
          ],
        );

    // Pair two fields into a row on wide screens; stack them on mobile.
    Widget pairOr(Widget a, Widget b) => twoCol ? row2(a, b) : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [a, gap(), b],
        );

    final model = CustomTextField(
      controller: _modelController,
      focusNode: _modelNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _focus(_serialNode),
      label: 'Model',
      hintText: 'e.g. Latitude 5400',
    );
    final serial = CustomTextField(
      controller: _serialController,
      focusNode: _serialNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _focus(_problemNode),
      label: 'Serial Number',
      hintText: 'Optional',
    );
    final estCost = CustomTextField(
      controller: _estCostController,
      focusNode: _estCostNode,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => _focus(_advanceNode),
      label: 'Estimated Cost',
      hintText: '0',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
    );
    final advance = CustomTextField(
      controller: _advanceController,
      focusNode: _advanceNode,
      textInputAction: TextInputAction.done,
      label: 'Advance Paid',
      hintText: '0',
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ],
    );
    final received = _dateField(
      label: 'Received Date',
      value: _receivedDate,
      onPick: (d) => setState(() => _receivedDate = d),
    );
    final expected = _dateField(
      label: 'Expected Date',
      value: _expectedDate,
      onPick: (d) => setState(() => _expectedDate = d),
      allowClear: true,
      onClear: () => setState(() => _expectedDate = null),
    );

    final customerSec = _section(
      icon: TablerIcons.user,
      title: 'Customer',
      children: [_customerSection(customers)],
    );
    final deviceSec = _section(
      icon: TablerIcons.device_laptop,
      title: 'Device',
      children: [
        pairOr(_deviceTypeDropdown(), _brandField(brands)),
        gap(),
        pairOr(model, serial),
        gap(16),
        _photoPicker(),
      ],
    );
    final problemSec = _section(
      icon: TablerIcons.alert_triangle,
      title: 'Problem & Accessories',
      children: [
        CustomTextField(
          controller: _problemController,
          focusNode: _problemNode,
          label: 'Reported Problem',
          hintText: 'e.g. Not turning on, screen cracked',
          maxLines: 3,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Describe the problem' : null,
        ),
        gap(),
        CustomTextField(
          controller: _accessoriesController,
          focusNode: _accessoriesNode,
          label: 'Accessories Received',
          hintText: 'e.g. Charger, bag, mouse',
          maxLines: 2,
        ),
      ],
    );
    final itemsSec = _section(
      icon: TablerIcons.package,
      title: 'Items / Parts',
      trailing: TextButton.icon(
        onPressed: _showAddItemSheet,
        icon: Icon(TablerIcons.plus, size: 16.spMin),
        label: Text('Add Item', style: TextStyle(fontSize: 12.spMin)),
      ),
      children: [_itemsList()],
    );
    final costSec = _section(
      icon: TablerIcons.cash,
      title: 'Cost & Dates',
      children: [
        row2(estCost, advance),
        gap(),
        row2(received, expected),
      ],
    );

    final submit = Padding(
      padding: EdgeInsets.symmetric(vertical: 4.spMin),
      child: AppButton().primaryButton(
        text: _isEditing ? 'Save Changes' : 'Add Repair',
        onPressed: _save,
        height: 48.spMin,
        borderRadius: 12,
      ),
    );

    return [
      customerSec,
      deviceSec,
      problemSec,
      itemsSec,
      costSec,
      submit,
      SizedBox(height: 8.spMin),
    ];
  }

  // ---- pieces -----------------------------------------------------------

  /// A titled, full-width section card (settings-style: rounded, subtle
  /// elevation, no border).
  Widget _section({
    required IconData icon,
    required String title,
    Widget? trailing,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.spMin),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.spMin),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18.spMin, color: AppColors.primary),
                SizedBox(width: 8.spMin),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                if (trailing != null) ...[const Spacer(), trailing],
              ],
            ),
            SizedBox(height: 12.spMin),
            ...children,
          ],
        ),
      ),
    );
  }

  // ---- Repair items (parts/services) -----------------------------------

  Widget _itemsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 24.spMin, vertical: 24.spMin),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.spMin),
        ),
        child: _AddRepairItemSheet(
          onAdd: (item) {
            setState(() => _items.add(item));
            _syncEstimatedCostToItems();
          },
        ),
      ),
    );
  }

  /// Customer selector: a Walk-in / Registered toggle. Walk-in collects
  /// nothing; Registered shows a name field that searches existing customers
  /// (mirrors the sales cart's customer picker) plus a phone field.
  Widget _customerSection(List<Customer> customers) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _custTypeChip(
              icon: TablerIcons.walk,
              label: 'Walk-in',
              selected: _isWalkIn,
              onTap: () => setState(() {
                _isWalkIn = true;
                _showSuggestions = false;
                _customerId = null;
                _nameController.clear();
                _phoneController.clear();
              }),
            ),
            SizedBox(width: 8.spMin),
            _custTypeChip(
              icon: TablerIcons.user,
              label: 'Registered',
              selected: !_isWalkIn,
              onTap: () => setState(() => _isWalkIn = false),
            ),
          ],
        ),
        SizedBox(height: 12.spMin),
        if (_isWalkIn)
          _walkInNote(isDark)
        else ...[
          _customerNameField(customers),
          SizedBox(height: 12.spMin),
          CustomTextField(
            controller: _phoneController,
            focusNode: _phoneNode,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _focus(_brandNode),
            label: 'Phone',
            hintText: 'e.g. 03001234567',
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
              LengthLimitingTextInputFormatter(15),
            ],
          ),
        ],
      ],
    );
  }

  Widget _custTypeChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10.spMin),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.spMin),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.spMin),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.spMin,
                color: selected ? AppColors.primary : Colors.grey[600],
              ),
              SizedBox(width: 6.spMin),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.spMin,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? AppColors.primary : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walkInNote(bool isDark) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.spMin),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(10.spMin),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.info_circle, size: 16.spMin, color: AppColors.primary),
          SizedBox(width: 8.spMin),
          Expanded(
            child: Text(
              'Walk-in customer — no customer details are saved. Just add the '
              'device and problem below.',
              style: TextStyle(
                fontSize: 11.spMin,
                color: isDark ? AppColors.grey300 : AppColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Name field for registered customers: typing filters existing customers
  /// into an inline suggestions list; picking one links it (sets [_customerId]).
  Widget _customerNameField(List<Customer> customers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _nameController,
          focusNode: _nameNode,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _focus(_phoneNode),
          label: 'Customer Name',
          hintText: 'Type to search or add a new name',
          prefixIcon: Icon(
            TablerIcons.search,
            size: 18.spMin,
            color: AppColors.primary,
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Customer name is required'
              : null,
          onChange: (v) {
            setState(() {
              // Editing the name unlinks any previously picked customer.
              _customerId = null;
              _showSuggestions = (v ?? '').trim().isNotEmpty;
            });
            return null;
          },
        ),
        if (_showSuggestions) _customerSuggestions(customers),
      ],
    );
  }

  Widget _customerSuggestions(List<Customer> customers) {
    final q = _nameController.text.trim().toLowerCase();
    if (q.isEmpty) return const SizedBox.shrink();
    final seen = <String>{};
    final matches = <Customer>[];
    for (final c in customers) {
      if (c.id.isEmpty || !seen.add(c.id)) continue;
      if (c.name.toLowerCase().contains(q) ||
          c.phoneNumber.toLowerCase().contains(q)) {
        matches.add(c);
      }
    }
    if (matches.isEmpty) return const SizedBox.shrink();
    return _suggestionsScrollBox(
      itemCount: matches.length,
      itemBuilder: (context, i) => _suggestionRow(
        matches[i],
        showDivider: i != matches.length - 1,
      ),
    );
  }

  /// Bordered dropdown that shows up to 4 rows then scrolls the rest. Shared by
  /// the customer and brand search fields.
  Widget _suggestionsScrollBox({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visibleRows = itemCount < 4 ? itemCount : 4;
    return Container(
      margin: EdgeInsets.only(top: 6.spMin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dCardColor : AppColors.lCardColor,
        borderRadius: BorderRadius.circular(10.spMin),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: visibleRows * _suggestionRowH.spMin,
        child: Scrollbar(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        ),
      ),
    );
  }

  // ---- Brand search ----------------------------------------------------

  Widget _brandField(List<Brand> brands) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _brandController,
          focusNode: _brandNode,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _focus(_modelNode),
          label: 'Brand',
          hintText: 'Type to search brands',
          prefixIcon: Icon(
            TablerIcons.search,
            size: 18.spMin,
            color: AppColors.primary,
          ),
          onChange: (v) {
            setState(() => _showBrandSuggestions = (v ?? '').trim().isNotEmpty);
            return null;
          },
        ),
        if (_showBrandSuggestions) _brandSuggestions(brands),
      ],
    );
  }

  Widget _brandSuggestions(List<Brand> brands) {
    final q = _brandController.text.trim().toLowerCase();
    if (q.isEmpty) return const SizedBox.shrink();
    final matches =
        brands.where((b) => b.name.toLowerCase().contains(q)).toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    return _suggestionsScrollBox(
      itemCount: matches.length,
      itemBuilder: (context, i) => _brandRow(
        matches[i],
        showDivider: i != matches.length - 1,
      ),
    );
  }

  Widget _brandRow(Brand b, {required bool showDivider}) {
    return InkWell(
      onTap: () {
        setState(() {
          _brandController.text = b.name;
          _showBrandSuggestions = false;
        });
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: _suggestionRowH.spMin,
        padding: EdgeInsets.symmetric(horizontal: 12.spMin),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          children: [
            Icon(TablerIcons.tag, size: 18.spMin, color: AppColors.primary),
            SizedBox(width: 8.spMin),
            Expanded(
              child: Text(
                b.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.spMin,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionRow(
    Customer c, {
    required bool showDivider,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _customerId = c.id;
          _nameController.text = c.name;
          _phoneController.text = c.phoneNumber;
          _showSuggestions = false;
        });
        FocusScope.of(context).unfocus();
      },
      child: Container(
        height: _suggestionRowH.spMin,
        padding: EdgeInsets.symmetric(horizontal: 12.spMin),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(bottom: BorderSide(color: AppColors.border))
              : null,
        ),
        child: Row(
          children: [
            Icon(TablerIcons.user, size: 18.spMin, color: AppColors.primary),
            SizedBox(width: 8.spMin),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.spMin,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (c.phoneNumber.isNotEmpty)
                    Text(
                      c.phoneNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.spMin,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
    // Tap anywhere on the box to pick a photo; a corner ✕ removes it.
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 170.spMin,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.spMin),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.file(File(_imagePath!), fit: BoxFit.cover)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    TablerIcons.camera_plus,
                    color: AppColors.primary,
                    size: 34.spMin,
                  ),
                  SizedBox(height: 8.spMin),
                  Text(
                    'Tap to add device photo',
                    style: TextStyle(
                      fontSize: 12.spMin,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            if (hasImage)
              Positioned(
                top: 8.spMin,
                right: 8.spMin,
                child: GestureDetector(
                  onTap: () => setState(() => _imagePath = null),
                  child: Container(
                    padding: EdgeInsets.all(4.spMin),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      TablerIcons.x,
                      size: 16.spMin,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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
      // Walk-in: take nothing (no linked customer, generic name). Registered:
      // save the linked/typed customer + phone.
      customerId: _isWalkIn ? null : _customerId,
      clearCustomerId: _isWalkIn,
      clientName: _isWalkIn ? 'Walk-in' : _nameController.text.trim(),
      clientPhone: _isWalkIn ? '' : _phoneController.text.trim(),
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
  final _productSearchController = TextEditingController();
  bool _showProductSuggestions = false;
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
    _productSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsNotifierProvider);
    final products = productsAsync.asData?.value ?? const <Product>[];

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.spMin),
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
                    _productSearchController.clear();
                    _showProductSuggestions = false;
                  });
                }),
                SizedBox(width: 8.spMin),
                _modeChip('Custom Item', _custom, () {
                  setState(() {
                    _custom = true;
                    _selectedProduct = null;
                    _nameController.clear();
                    _priceController.clear();
                    _productSearchController.clear();
                    _showProductSuggestions = false;
                  });
                }),
              ],
            ),
            SizedBox(height: 16.spMin),

            if (!_custom) ...[
              _productSearchField(products),
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
      ),
    );
  }

  /// Searchable inventory product picker: type to filter, results show the
  /// product image + name + price; tap to select (fills name & price).
  Widget _productSearchField(List<Product> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          controller: _productSearchController,
          label: 'Product',
          hintText:
              products.isEmpty ? 'No products available' : 'Search products',
          prefixIcon: Icon(
            TablerIcons.search,
            size: 18.spMin,
            color: AppColors.primary,
          ),
          onChange: (v) {
            setState(() {
              _showProductSuggestions = (v ?? '').trim().isNotEmpty;
              _selectedProduct = null; // typing unlinks the picked product
            });
            return null;
          },
        ),
        if (_showProductSuggestions) _productSuggestions(products),
      ],
    );
  }

  Widget _productSuggestions(List<Product> products) {
    final q = _productSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return const SizedBox.shrink();
    final matches =
        products.where((p) => p.name.toLowerCase().contains(q)).toList();
    if (matches.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowH = 56.spMin;
    final visible = matches.length < 4 ? matches.length : 4;
    return Container(
      margin: EdgeInsets.only(top: 6.spMin),
      decoration: BoxDecoration(
        color: isDark ? AppColors.dCardColor : AppColors.lCardColor,
        borderRadius: BorderRadius.circular(10.spMin),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: visible * rowH,
        child: Scrollbar(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final p = matches[i];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedProduct = p;
                    _nameController.text = p.name;
                    _priceController.text = p.price.toStringAsFixed(0);
                    _productSearchController.text = p.name;
                    _showProductSuggestions = false;
                  });
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  height: rowH,
                  padding: EdgeInsets.symmetric(horizontal: 10.spMin),
                  decoration: BoxDecoration(
                    border: i != matches.length - 1
                        ? Border(bottom: BorderSide(color: AppColors.border))
                        : null,
                  ),
                  child: Row(
                    children: [
                      CachedProductImage(
                        imageUrl: p.imageUrl,
                        width: 38.spMin,
                        height: 38.spMin,
                        borderRadius: BorderRadius.circular(8.spMin),
                      ),
                      SizedBox(width: 10.spMin),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.spMin,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Rs ${p.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11.spMin,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
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
