// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api

import 'dart:io';
import 'package:desktopapp/res/components/app_bar_widget.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:desktopapp/res/colors/app_color.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/items_model.dart';
import '../../models/brand_model.dart';
import '../../models/category_model.dart';
import '../../res/assets/image_assets.dart';
import '../../res/components/app_icon.dart';
import '../../res/components/app_text_widgrt.dart';
import '../../res/components/text_field_widget.dart';
import '../../view_models/providers/add_prduct_provider.dart';
import '../../view_models/states/add_product_states.dart';
import '../../view_models/services/database/database_services.dart';
import '../home/rapper.dart';

// Provider to load brands
final brandsProvider = FutureProvider.autoDispose<List<Brand>>((ref) async {
  final dbService = DatabaseService();
  return await dbService.getBrands();
});

// Provider to load categories
final categoriesProvider = FutureProvider.autoDispose<List<Category>>((
  ref,
) async {
  final dbService = DatabaseService();
  return await dbService.getCategories();
});

class AddProductScreen extends ConsumerStatefulWidget {
  final Product? product;

  /// Whether this is a service. Pass `null` to let the user choose the type
  /// on this same page (the two selection cards are shown first). When
  /// editing an existing product the type is taken from the product.
  final bool? isService;
  final String? initialName;

  const AddProductScreen({
    super.key,
    this.product,
    this.isService,
    this.initialName,
  });

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// The currently selected type. Null until the user picks one (only
  /// possible when [widget.isService] was not supplied and we're not editing).
  bool? _isService;

  /// True once a type has been chosen (or supplied) so the form can show.
  bool get _hasType => _isService != null;

  /// Type cannot be changed while editing an existing product.
  bool get _typeLocked => widget.product != null;

  // Declare controllers
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;
  late TextEditingController _barcodeController;

  /// Check if running on mobile platform
  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  /// Open barcode scanner and set the result to barcode field
  Future<void> _openBarcodeScanner(ProductFormNotifier formNotifier) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const _BarcodeScannerPage(),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      _barcodeController.text = result;
      formNotifier.updateBarcode(result);
    }
  }

  @override
  void initState() {
    super.initState();
    // Determine the initial type: explicit param > existing product >
    // default to Item (isService = false) so the form is ready immediately.
    _isService = widget.isService ?? widget.product?.isService ?? false;

    // Initialize controllers with initial values from formState
    final formState = ref.read(productFormProvider(widget.product));
    // Use initialName if provided, otherwise use formState name
    _nameController = TextEditingController(
      text: widget.initialName ?? formState.name,
    );
    _priceController = TextEditingController(text: formState.price?.toString());
    _purchasePriceController = TextEditingController(
      text: formState.purchasePrice?.toString(),
    );
    _stockController = TextEditingController(text: formState.stock?.toString());
    _descriptionController = TextEditingController(text: formState.description);
    _barcodeController = TextEditingController(text: formState.barcode);

    // If initialName is provided, update the form state as well
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(productFormProvider(widget.product).notifier)
            .updateName(widget.initialName!);
      });
    }
  }

  @override
  void didUpdateWidget(AddProductScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if the product changes (e.g., navigating to edit a different product)
    if (oldWidget.product != widget.product) {
      final formState = ref.read(productFormProvider(widget.product));
      _nameController.text = formState.name ?? '';
      _priceController.text = formState.price?.toString() ?? '';
      _purchasePriceController.text = formState.purchasePrice?.toString() ?? '';
      _stockController.text = formState.stock?.toString() ?? '';
      _descriptionController.text = formState.description ?? '';
      _barcodeController.text = formState.barcode ?? '';
    }
  }

  @override
  void dispose() {
    // Dispose of controllers to prevent memory leaks
    _nameController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = _isService == null ? 'Item' : (_isService! ? 'Service' : 'Item');
    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title:
            widget.product == null
                ? (_hasType ? 'Add New $typeLabel' : 'Add New Item/Service')
                : 'Edit $typeLabel',
        context: context,
      ),
      body: ResponsiveWrapper(
        mobile: _buildMobileForm(context, ref),
        tablet: _buildTabletForm(context, ref),
        desktop: _buildDesktopForm(context, ref),
      ),
    );
  }

  /// Select a type and (when not editing) update the form state accordingly.
  void _selectType(bool isService) {
    if (_typeLocked) return;
    setState(() => _isService = isService);
    ref.read(productFormProvider(widget.product).notifier).updateIsService(isService);
  }

  /// The two Item / Service selection cards shown at the top of the page.
  Widget _buildTypeSelector(BuildContext context) {
    return Row(
      children: [
        _buildTypeCard(
          title: 'Services',
          win11IconPath: ImageAssets.win11Services,
          icon: Icons.build,
          isService: true,
        ),
        SizedBox(width: 16.w),
        _buildTypeCard(
          title: 'Items',
          win11IconPath: ImageAssets.win11OpenBox,
          icon: Icons.inventory,
          isService: false,
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required String title,
    required String win11IconPath,
    required IconData icon,
    required bool isService,
  }) {
    final bool selected = _isService == isService;
    // Compact once a choice has been made; large prompt cards before that.
    final bool compact = _hasType;
    final Color baseColor =
        selected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4);

    return Expanded(
      child: Opacity(
        opacity: _typeLocked && !selected ? 0.5 : 1,
        child: GestureDetector(
          onTap: _typeLocked ? null : () => _selectType(isService),
          child: Card(
            elevation: selected ? 6 : 2,
            shadowColor: Colors.black.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Container(
              height: compact ? 70.h : 200.h,
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: selected ? 0.2 : 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: selected ? AppColors.primary : baseColor,
                  width: selected ? 1.8 : 1.2,
                ),
              ),
              child:
                  compact
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            win11IconPath: win11IconPath,
                            defaultIcon: icon,
                            size: 24.spMin,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15.spMin,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AppIcon(
                            win11IconPath: win11IconPath,
                            defaultIcon: icon,
                            size: 50.spMin,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 20.spMin,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileForm(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: _buildForm(context, ref),
    );
  }

  Widget _buildTabletForm(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: _buildForm(context, ref),
    );
  }

  Widget _buildDesktopForm(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 900.w),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
          child: _buildForm(context, ref),
        ),
      ),
    );
  }

  /// Whether the current layout should place two fields per row.
  bool _isTwoColumn(BuildContext context) =>
      AppSizes.isTablet(context) || AppSizes.isDesktop(context);

  Widget _buildForm(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(productFormProvider(widget.product));
    final formNotifier = ref.read(productFormProvider(widget.product).notifier);
    final isEditing = widget.product != null;
    final typeWord = (_isService ?? false) ? 'Service' : 'Item';
    final buttonText = isEditing ? 'Update $typeWord' : 'Add $typeWord';
    final fieldConfigs = formState.fieldConfigs;
    final fieldErrors =
        formState.fieldErrors; // Get from state instead of local

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.horizontalPaddingSm.w,
        vertical: AppSizes.verticalPaddingSm,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step 1: Item / Service selection (kept on the same page).
            _buildTypeSelector(context),
            SizedBox(height: 20.h),

            // Until a type is chosen, prompt and stop here.
            if (!_hasType)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Text(
                  'Select Item or Service to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.spMin,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.grey300
                            : AppColors.grey600,
                  ),
                ),
              ),

            if (_hasType) ...[
            // Image Picker
            if (fieldConfigs['imageFile']!.isShow) ...[
              Stack(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await formNotifier.pickImage();
                    },
                    child: Container(
                      height: 250.h,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.dTFieldHintColor
                                  : AppColors.lTFieldHintColor ??
                                      AppColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child:
                            formState.imageFile != null
                                ? Image.file(
                                  formState.imageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                )
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppIcon(
                                        win11IconPath:
                                            ImageAssets.win11AddImage,
                                        defaultIcon: Icons.add_a_photo_outlined,
                                        size: 25.spMin,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.dIconColor
                                                : AppColors.lIconColor,
                                      ),

                                      SizedBox(height: 8.h),
                                      smTextBold(
                                        text:
                                            fieldConfigs['imageFile']!.hintText,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? AppColors.grey100
                                                : AppColors.grey700,
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                  ),
                  if (formState.imageFile != null)
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: IconButton(
                        icon: AppIcon(
                          win11IconPath: ImageAssets.win11Cancel,
                          defaultIcon: Icons.cancel,
                          color: Colors.red,
                          size: 18.spMin,
                        ),

                        onPressed: () => formNotifier.updateImageFile(null),
                      ),
                    ),
                ],
              ),
              if (fieldConfigs['imageFile']!.isRequired &&
                  formState.imageFile == null &&
                  widget.product?.imageUrl == null)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: smText(
                    text: fieldConfigs['imageFile']!.validatorText,
                    color: AppColors.error,
                  ),
                ),
              SizedBox(height: 20.h),
            ],

            // Name Field — always full width (one line).
            if (fieldConfigs['name']!.isShow)
              CustomTextField(
                controller: _nameController,
                label:
                    fieldConfigs['name']!.isRequired
                        ? fieldConfigs['name']!.title
                        : fieldConfigs['name']!.title,
                lableColor:
                    (fieldErrors['name'] ?? false) &&
                            fieldConfigs['name']!.isRequired
                        ? AppColors.error
                        : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dTFieldHintColor
                        : AppColors.lTFieldHintColor,
                hintText: fieldConfigs['name']!.hintText,
                filled: true,
                prefixIcon: AppIcon(
                  win11IconPath: ImageAssets.win11Label,
                  defaultIcon: Icons.label_outline,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  size: 20.spMin,
                ),

                validator: (value) {
                  final hasError =
                      fieldConfigs['name']!.isRequired &&
                      (value == null || value.isEmpty);
                  return hasError ? fieldConfigs['name']!.validatorText : null;
                },
                onChange: (value) {
                  formNotifier.updateName(value ?? '');
                  return null;
                },
              ),
            SizedBox(height: 16.h),

            // Other Fields — paired two-per-row on tablet/desktop.
            ..._layoutFields(
              context,
              _buildOtherFields(
                formState,
                formNotifier,
                _isService ?? false,
                context,
              ),
            ),

            // // Timestamps
            // if (isEditing) ...[
            //   SizedBox(height: 16.h),
            //   Container(
            //     padding: EdgeInsets.all(12.h),
            //     decoration: BoxDecoration(
            //       border: Border.all(color: Colors.grey.shade200),
            //       borderRadius: BorderRadius.circular(8.r),
            //     ),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Text(
            //           'Created: ${formState.createdAt?.toString().substring(0, 16) ?? 'N/A'}',
            //           style: TextStyle(
            //             fontSize: 14.spMin,
            //             color: Colors.grey.shade700,
            //           ),
            //         ),
            //         SizedBox(height: 8.h),
            //         Text(
            //           'Updated: ${formState.updatedAt?.toString().substring(0, 16) ?? 'N/A'}',
            //           style: TextStyle(
            //             fontSize: 14.spMin,
            //             color: Colors.grey.shade700,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ],

            // Error Message
            if (formState.errorMessage != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Text(
                  formState.errorMessage!,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14.spMin,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Submit Button
            AnimatedScale(
              scale: formState.isLoading ? 0.95 : 1.0,
              duration: Duration(milliseconds: 200),
              child: AppButton().primaryButton(
                text: buttonText,
                isLoading: formState.isLoading,
                onPressed: () async {
                  formNotifier.validateAllFields(); // Use Riverpod validation
                  if (_formKey.currentState!.validate()) {
                    final success = await formNotifier.submitForm();
                    if (success && mounted) {
                      final successMessage =
                          '${(_isService ?? false) ? 'Service' : 'Product'} ${widget.product != null ? 'updated' : 'added'} successfully!';

                      // Clear all text controllers
                      _nameController.clear();
                      _priceController.clear();
                      _purchasePriceController.clear();
                      _stockController.clear();
                      _descriptionController.clear();
                      _barcodeController.clear();

                      // Reset form state
                      formNotifier.resetForm();

                      // Reset form validation
                      _formKey.currentState?.reset();

                      // Navigate back first, then show success message
                      if (mounted && context.mounted) {
                        Navigator.of(context).pop({'success': true, 'message': successMessage});
                      }
                    }
                  }
                },
              ),
            ),
            ], // end of if (_hasType)
          ],
        ),
      ),
    );
  }

  /// Arranges the given field widgets vertically (mobile) or two-per-row
  /// (tablet/desktop), inserting consistent spacing between rows.
  List<Widget> _layoutFields(BuildContext context, List<Widget> fields) {
    const double gap = 16;
    if (!_isTwoColumn(context)) {
      // Single column: one field per row with spacing between.
      final out = <Widget>[];
      for (var i = 0; i < fields.length; i++) {
        out.add(fields[i]);
        if (i != fields.length - 1) out.add(SizedBox(height: gap.h));
      }
      return out;
    }

    // Two columns: pair fields up.
    final rows = <Widget>[];
    for (var i = 0; i < fields.length; i += 2) {
      final left = fields[i];
      final hasRight = i + 1 < fields.length;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: gap.w),
            Expanded(
              child: hasRight ? fields[i + 1] : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < fields.length) rows.add(SizedBox(height: gap.h));
    }
    return rows;
  }

  List<Widget> _buildOtherFields(
    ProductFormState formState,
    ProductFormNotifier formNotifier,
    bool isService,
    BuildContext context,
  ) {
    final fieldConfigs = formState.fieldConfigs;
    final fieldErrors = formState.fieldErrors; // Get from state
    final fields = <Widget>[];

    // Price
    if (fieldConfigs['price']!.isShow) {
      fields.add(
        CustomTextField(
          controller: _priceController,
          label:
              fieldConfigs['price']!.isRequired
                  ? fieldConfigs['price']!.title
                  : fieldConfigs['price']!.title,
          lableColor:
              (fieldErrors['price'] ?? false) &&
                      fieldConfigs['price']!.isRequired
                  ? AppColors.error
                  : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.dTFieldHintColor
                  : AppColors.lTFieldHintColor,
          hintText: fieldConfigs['price']!.hintText,
          keyboardType: TextInputType.number,
          filled: true,
          prefixIcon: AppIcon(
            win11IconPath: ImageAssets.win11DollarBag,
            defaultIcon: Icons.attach_money,
            color: AppColors.primary.withValues(alpha: 0.7),
            size: 20.spMin,
          ),

          validator: (value) {
            final hasError =
                fieldConfigs['price']!.isRequired &&
                (double.tryParse(value ?? '') == null ||
                    double.parse(value!) <= 0);
            return hasError ? fieldConfigs['price']!.validatorText : null;
          },
          onChange: (value) {
            formNotifier.updatePrice(value ?? '');
            return null;
          },
        ),
      );
    }

    // Product-specific fields
    if (!isService) {
      if (fieldConfigs['purchasePrice']!.isShow) {
        fields.add(
          CustomTextField(
            controller: _purchasePriceController,
            label:
                fieldConfigs['purchasePrice']!.isRequired
                    ? fieldConfigs['purchasePrice']!.title
                    : fieldConfigs['purchasePrice']!.title,
            lableColor:
                (fieldErrors['purchasePrice'] ?? false) &&
                        fieldConfigs['purchasePrice']!.isRequired
                    ? AppColors.error
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dTFieldHintColor
                    : AppColors.lTFieldHintColor,
            hintText: fieldConfigs['purchasePrice']!.hintText,
            keyboardType: TextInputType.number,
            filled: true,
            prefixIcon: AppIcon(
              win11IconPath: ImageAssets.win11PriceTag,
              defaultIcon: Icons.shopping_cart_outlined,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 20.spMin,
            ),

            validator: (value) {
              final hasError =
                  fieldConfigs['purchasePrice']!.isRequired &&
                  (double.tryParse(value ?? '') == null ||
                      double.parse(value!) <= 0);
              return hasError
                  ? fieldConfigs['purchasePrice']!.validatorText
                  : null;
            },
            onChange: (value) {
              formNotifier.updatePurchasePrice(value ?? '');
              return null;
            },
          ),
        );
      }

      if (fieldConfigs['stock']!.isShow) {
        fields.add(
          CustomTextField(
            controller: _stockController,
            label:
                fieldConfigs['stock']!.isRequired
                    ? fieldConfigs['stock']!.title
                    : fieldConfigs['stock']!.title,
            lableColor:
                (fieldErrors['stock'] ?? false) &&
                        fieldConfigs['stock']!.isRequired
                    ? AppColors.error
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dTFieldHintColor
                    : AppColors.lTFieldHintColor,
            hintText: fieldConfigs['stock']!.hintText,
            keyboardType: TextInputType.number,
            filled: true,
            prefixIcon: AppIcon(
              win11IconPath: ImageAssets.win11Stock,
              defaultIcon: Icons.inventory_2_outlined,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 20.spMin,
            ),

            validator: (value) {
              final hasError =
                  fieldConfigs['stock']!.isRequired &&
                  (int.tryParse(value ?? '') == null || int.parse(value!) < 0);
              return hasError ? fieldConfigs['stock']!.validatorText : null;
            },
            onChange: (value) {
              formNotifier.updateStock(value ?? '');
              return null;
            },
          ),
        );
      }

      // Barcode Field
      if (fieldConfigs['barcode']!.isShow) {
        fields.add(
          CustomTextField(
            controller: _barcodeController,
            label: fieldConfigs['barcode']!.title,
            lableColor:
                (fieldErrors['barcode'] ?? false) &&
                        fieldConfigs['barcode']!.isRequired
                    ? AppColors.error
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dTFieldHintColor
                    : AppColors.lTFieldHintColor,
            hintText: fieldConfigs['barcode']!.hintText,
            filled: true,
            prefixIcon: _isMobilePlatform
                ? GestureDetector(
                    onTap: () => _openBarcodeScanner(formNotifier),
                    child: AppIcon(
                      win11IconPath: ImageAssets.win11QrCode,
                      defaultIcon: Icons.qr_code_scanner,
                      color: AppColors.primary,
                      size: 20.spMin,
                    ),
                  )
                : AppIcon(
                    win11IconPath: ImageAssets.win11QrCode,
                    defaultIcon: Icons.qr_code_scanner,
                    color: AppColors.primary.withValues(alpha: 0.7),
                    size: 20.spMin,
                  ),
            suffixIcon: _isMobilePlatform
                ? IconButton(
                    onPressed: () => _openBarcodeScanner(formNotifier),
                    icon: AppIcon(
                      win11IconPath: ImageAssets.win11QrCode,
                      defaultIcon: Icons.qr_code_scanner,
                      color: AppColors.primary,
                      size: 20.spMin,
                    ),
                    tooltip: 'Scan Barcode',
                  )
                : null,
            validator: (value) {
              final hasError =
                  fieldConfigs['barcode']!.isRequired &&
                  (value == null || value.isEmpty);
              return hasError ? fieldConfigs['barcode']!.validatorText : null;
            },
            onChange: (value) {
              formNotifier.updateBarcode(value ?? '');
              return null;
            },
          ),
        );
      }

      if (fieldConfigs['condition']!.isShow) {
        fields.add(
          AppDropdown<String>(
            prefixIcon: AppIcon(
              win11IconPath: ImageAssets.win11AppsTab,
              defaultIcon: Icons.auto_awesome_motion,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 20.spMin,
            ),
            label:
                fieldConfigs['condition']!.isRequired
                    ? fieldConfigs['condition']!.title
                    : fieldConfigs['condition']!.title,
            lableColor:
                (fieldErrors['condition'] ?? false) &&
                        fieldConfigs['condition']!.isRequired
                    ? AppColors.error
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dTFieldHintColor
                    : AppColors.lTFieldHintColor,
            hintText: fieldConfigs['condition']!.hintText,
            value: formState.condition,
            items: const ['New', 'Used'],
            displayItems: const ['New', 'Used'],
            filled: true,
            onChanged: (value) {
              formNotifier.updateCondition(value);
            },
          ),
        );
      }

      if (fieldConfigs['brand']!.isShow) {
        final brandsAsync = ref.watch(brandsProvider);
        fields.add(
          brandsAsync.when(
            data: (brands) {
              // Use toSet() to ensure unique brand names (avoid dropdown assertion error)
              final brandNames = brands.map((b) => b.name).toSet().toList();
              return AppDropdown<String>(
                prefixIcon: AppIcon(
                  win11IconPath: ImageAssets.win11Brand,
                  defaultIcon: Icons.branding_watermark_rounded,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  size: 20.spMin,
                ),
                label:
                    fieldConfigs['brand']!.isRequired
                        ? fieldConfigs['brand']!.title
                        : fieldConfigs['brand']!.title,
                lableColor:
                    (fieldErrors['brand'] ?? false) &&
                            fieldConfigs['brand']!.isRequired
                        ? AppColors.error
                        : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dTFieldHintColor
                        : AppColors.lTFieldHintColor,
                hintText: fieldConfigs['brand']!.hintText,
                value:
                    formState.brand != null &&
                            brandNames.contains(formState.brand)
                        ? formState.brand
                        : null,
                items: brandNames,
                displayItems: brandNames,
                filled: true,
                onChanged: (value) {
                  formNotifier.updateBrand(value ?? '');
                },
              );
            },
            loading:
                () => Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? (AppColors.dTFieldHintColor)
                              : (AppColors.lTFieldHintColor ?? Colors.grey),
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Loading brands...',
                        style: TextStyle(
                          fontSize: 14.spMin,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.dTFieldHintColor
                                  : AppColors.lTFieldHintColor,
                        ),
                      ),
                    ],
                  ),
                ),
            error:
                (error, stack) => Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.error),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        win11IconPath: ImageAssets.win11Siren,
                        defaultIcon: Icons.error_outline,
                        color: AppColors.error,
                        size: 20.spMin,
                      ),

                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Error loading brands',
                          style: TextStyle(
                            fontSize: 14.spMin,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        );
      }

      // Category Dropdown
      if (fieldConfigs['category']!.isShow) {
        final categoriesAsync = ref.watch(categoriesProvider);
        fields.add(
          categoriesAsync.when(
            data: (categories) {
              // Use toSet() to ensure unique category names (avoid dropdown assertion error)
              final categoryNames =
                  categories.map((c) => c.name).toSet().toList();
              return AppDropdown<String>(
                prefixIcon: AppIcon(
                  win11IconPath: ImageAssets.win11Category,
                  defaultIcon: Icons.category,
                  color: AppColors.primary.withValues(alpha: 0.7),
                  size: 20.spMin,
                ),
                label:
                    fieldConfigs['category']!.isRequired
                        ? fieldConfigs['category']!.title
                        : fieldConfigs['category']!.title,
                lableColor:
                    (fieldErrors['category'] ?? false) &&
                            fieldConfigs['category']!.isRequired
                        ? AppColors.error
                        : Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dTFieldHintColor
                        : AppColors.lTFieldHintColor,
                hintText: fieldConfigs['category']!.hintText,
                value:
                    formState.category != null &&
                            categoryNames.contains(formState.category)
                        ? formState.category
                        : null,
                items: categoryNames,
                displayItems: categoryNames,
                filled: true,
                onChanged: (value) {
                  formNotifier.updateCategory(value ?? '');
                },
              );
            },
            loading:
                () => Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? (AppColors.dTFieldHintColor)
                              : (AppColors.lTFieldHintColor ?? Colors.grey),
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Loading categories...',
                        style: TextStyle(
                          fontSize: 14.spMin,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.dTFieldHintColor
                                  : AppColors.lTFieldHintColor,
                        ),
                      ),
                    ],
                  ),
                ),
            error:
                (error, stack) => Container(
                  height: 56.h,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.error),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        win11IconPath: ImageAssets.win11Cancel,
                        defaultIcon: Icons.error_outline,
                        color: AppColors.error,
                        size: 20.spMin,
                      ),

                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'Error loading categories',
                          style: TextStyle(
                            fontSize: 14.spMin,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        );
      }
    }

    // Description
    if (fieldConfigs['description']!.isShow) {
      fields.add(
        CustomTextField(
          controller: _descriptionController,
          label:
              fieldConfigs['description']!.isRequired
                  ? fieldConfigs['description']!.title
                  : fieldConfigs['description']!.title,
          lableColor:
              (fieldErrors['description'] ?? false) &&
                      fieldConfigs['description']!.isRequired
                  ? AppColors.error
                  : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.dTFieldHintColor
                  : AppColors.lTFieldHintColor,
          hintText: fieldConfigs['description']!.hintText,
          maxLines: 3,
          filled: true,
          prefixIcon: AppIcon(
            win11IconPath: ImageAssets.win11Doc2,
            defaultIcon: Icons.description_outlined,
            color: AppColors.primary.withValues(alpha: 0.7),
            size: 20.spMin,
          ),

          validator: (value) {
            final hasError =
                fieldConfigs['description']!.isRequired &&
                (value == null || value.isEmpty);
            return hasError ? fieldConfigs['description']!.validatorText : null;
          },
          onChange: (value) {
            formNotifier.updateDescription(value ?? '');
            return null;
          },
        ),
      );
    }

    return fields;
  }
}

/// Barcode Scanner Page for Add Product
class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        setState(() {
          _isScanning = false;
        });
        Navigator.pop(context, barcode.rawValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                final torchState = state.torchState;
                return Icon(
                  torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 280.w,
              height: 280.w,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
          ),
          // Instructions
          Positioned(
            bottom: 100.h,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Point camera at barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.spMin,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
