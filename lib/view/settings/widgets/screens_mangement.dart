// Screen Management Section Widget

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../../models/items_model.dart';
import '../../../res/assets/image_assets.dart';
import '../../../res/colors/app_color.dart';
import '../../../res/components/app_bar_widget.dart';
import '../../../res/components/app_flushbar.dart';
import '../../../res/components/app_expansion_tile.dart';
import '../../../res/components/app_icon.dart';
import '../../../res/components/app_text_widgrt.dart';
import '../../../res/components/text_field_widget.dart';
import '../../../view_models/providers/add_prduct_provider.dart';
import '../../sales/check_out_view.dart';
import 'custom_tile.dart';
import 'data_mange.dart';
import 'home_screnn_mange.dart';

/// Settings → Screen Management → Add Field. Lets the shop owner create a
/// brand-new form field (text / dropdown / checkbox) for products or the
/// checkout form. Returns the built [FieldConfig] (with `isCustom: true`)
/// or null when cancelled.
Future<FieldConfig?> showAddFieldDialog(BuildContext context) async {
  final titleController = TextEditingController();
  final hintController = TextEditingController();
  final optionsController = TextEditingController();
  WidgetType selectedType = WidgetType.textField;
  bool isRequired = false;

  return showDialog<FieldConfig>(
    context: context,
    builder:
        (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: mdText(text: 'Add Field'),
              content: SizedBox(
                width: 380.spMin,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextField(
                        label: 'Field name',
                        hintText: 'e.g. Batch No, IMEI, Measurements',
                        controller: titleController,
                        autofocus: true,
                      ),
                      SizedBox(height: 12.spMin),
                      mdTextBold(text: 'Field type'),
                      SizedBox(height: 6.spMin),
                      RadioGroup<WidgetType>(
                        groupValue: selectedType,
                        onChanged:
                            (v) => setDialogState(() => selectedType = v!),
                        child: Column(
                          children:
                              ListTile.divideTiles(
                                context: ctx,
                                tiles: [
                                  RadioListTile<WidgetType>(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Text input'),
                                    subtitle: const Text(
                                      'Free text the user types',
                                    ),
                                    value: WidgetType.textField,
                                  ),
                                  RadioListTile<WidgetType>(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Dropdown'),
                                    subtitle: const Text(
                                      'Pick from a list of options',
                                    ),
                                    value: WidgetType.dropdown,
                                  ),
                                  RadioListTile<WidgetType>(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Checkbox'),
                                    subtitle: const Text('Yes / no toggle'),
                                    value: WidgetType.checkbox,
                                  ),
                                ],
                              ).toList(),
                        ),
                      ),
                      if (selectedType == WidgetType.dropdown) ...[
                        SizedBox(height: 6.spMin),
                        CustomTextField(
                          label: 'Options (one per line)',
                          hintText: 'Option 1\nOption 2\nOption 3',
                          controller: optionsController,
                          maxLines: 4,
                        ),
                      ],
                      SizedBox(height: 12.spMin),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Required'),
                        value: isRequired,
                        onChanged:
                            (v) =>
                                setDialogState(() => isRequired = v ?? false),
                      ),
                      SizedBox(height: 6.spMin),
                      CustomTextField(
                        label: 'Hint text (optional)',
                        hintText: 'Shown inside the field',
                        controller: hintController,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: mdText(text: 'Cancel'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            AppFlushbar.error(
                              ctx,
                              message: 'Enter a field name first',
                            );
                            return;
                          }
                          final options =
                              selectedType == WidgetType.dropdown
                                  ? optionsController.text
                                      .split('\n')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList()
                                  : null;
                          if (selectedType == WidgetType.dropdown &&
                              (options == null || options.isEmpty)) {
                            AppFlushbar.error(
                              ctx,
                              message: 'Add at least one dropdown option',
                            );
                            return;
                          }
                          Navigator.pop(
                            ctx,
                            FieldConfig(
                              title: title,
                              isShow: true,
                              isRequired: isRequired,
                              hintText:
                                  hintController.text.trim().isNotEmpty
                                      ? hintController.text.trim()
                                      : 'Enter $title',
                              validatorText: '$title is required',
                              widgetType: selectedType,
                              options: options,
                              isCustom: true,
                            ),
                          );
                        },
                        child: const Text('Add Field'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
  );
}

/// Confirmation popup before a custom field is deleted.
Future<bool> confirmDeleteField(BuildContext context, String title) async {
  final ok = await showDialog<bool>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: mdText(text: 'Delete field?'),
          content: smText(
            maxLines: 6,
            text:
                'The "$title" field will be removed from the form and Settings. '
                'Values already saved on existing records are kept but will no '
                'longer be shown or editable.\n\nThis cannot be undone.',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: mdText(text: 'Cancel'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
  );
  return ok == true;
}

class ScreenManagementSection extends ConsumerWidget {
  final WidgetRef ref;

  const ScreenManagementSection({super.key, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: AppExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.symmetric(horizontal: 16.spMin),
        childrenPadding: EdgeInsets.all(10.spMin),
        title: mdTextBold(text: 'Screen Management'),
        children: [
          // Home Page Settings
          customTileWidget(
            context,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomePageSettingsPage(),
                ),
              );
            },
            'Home Page Settings',
            'Manage home page sections, banners & order',
            Colors.orange,
            TablerIcons.window,
            ImageAssets.win11Home,
          ),

          customTileWidget(
            context,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DataManagementPage()),
              );
            },
            'Data Management',
            'Manage brands and categories',
            Colors.purple,
            TablerIcons.category,
            ImageAssets.win11RubiksCube,
          ),
          customTileWidget(
            context,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const _ProductFormFieldsPage(),
                ),
              );
            },
            'Product Form Fields',
            'Configure product form fields',
            Colors.blue,
            TablerIcons.template,
            ImageAssets.win11FilingCabinet,
          ),
          customTileWidget(
            context,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const _CustomerFormFieldsPage(),
                ),
              );
            },
            'Customer & Payment Fields',
            'Configure checkout form fields',
            Colors.green,
            TablerIcons.list_details,
            ImageAssets.win11Category,
          ),
        ],
      ),
    );
  }
}

// Product Form Fields Page
class _ProductFormFieldsPage extends ConsumerWidget {
  const _ProductFormFieldsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productFormState = ref.watch(productFormProvider(null));
    final productFormNotifier = ref.read(productFormProvider(null).notifier);

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Product Form Fields',
        context: context,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.spMin),
        children: [
          Text(
            'Configure which fields to show in the product form',
            style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
          ),
          SizedBox(height: 12.spMin),
          // Add a brand-new field for this business (custom fields are saved,
          // rendered in the product form, and synced across devices).
          OutlinedButton.icon(
            onPressed: () async {
              final config = await showAddFieldDialog(context);
              if (config == null || !context.mounted) return;
              productFormNotifier.addFieldConfig(config);
              AppFlushbar.success(
                context,
                message: '"${config.title}" added to the product form',
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Field'),
          ),
          SizedBox(height: 16.spMin),
          ...productFormState.fieldConfigs.entries
              .where((entry) => !['isBackup', 'warranty'].contains(entry.key))
              .map(
                (entry) => _FieldConfigTile(
                  fieldName: entry.key,
                  fieldConfig: entry.value,
                  onDelete:
                      entry.value.isCustom
                          ? () async {
                            if (!await confirmDeleteField(
                              context,
                              entry.value.title,
                            )) {
                              return;
                            }
                            productFormNotifier.deleteFieldConfig(entry.key);
                          }
                          : null,
                  onShowChanged: (val) {
                    productFormNotifier.updateFieldConfig(
                      entry.key,
                      isShow: val,
                    );
                  },
                  onRequiredChanged: (val) {
                    productFormNotifier.updateFieldConfig(
                      entry.key,
                      isRequired: val,
                    );
                  },
                  onTitleChanged: (val) {
                    productFormNotifier.updateFieldConfig(
                      entry.key,
                      title: val,
                    );
                  },
                  onHintTextChanged: (val) {
                    productFormNotifier.updateFieldConfig(
                      entry.key,
                      hintText: val,
                    );
                  },
                  onValidatorTextChanged: (val) {
                    productFormNotifier.updateFieldConfig(
                      entry.key,
                      validatorText: val,
                    );
                  },
                  onOptionsChanged: (options) {
                    productFormNotifier.updateFieldConfig(
                      entry.key,
                      options: options,
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }
}

// Customer Form Fields Page
class _CustomerFormFieldsPage extends ConsumerStatefulWidget {
  const _CustomerFormFieldsPage();

  @override
  ConsumerState<_CustomerFormFieldsPage> createState() =>
      _CustomerFormFieldsPageState();
}

class _CustomerFormFieldsPageState
    extends ConsumerState<_CustomerFormFieldsPage> {
  Map<String, FieldConfig> _tempFieldConfigs = {};
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with the SAVED field configs (including any custom fields
    // the user added), not the provider's built-in defaults.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final saved =
          await ref.read(databaseServiceProvider).getCustomerFieldConfigs();
      if (!mounted) return;
      ref.read(customerFormProvider.notifier).replaceAllFieldConfigs(saved);
      setState(() {
        _tempFieldConfigs = Map<String, FieldConfig>.from(
          ref.read(customerFormProvider).fieldConfigs,
        );
      });
    });
  }

  void _updateTempFieldConfig(
    String fieldName, {
    bool? isShow,
    bool? isRequired,
    String? hintText,
    String? validatorText,
    String? title,
    List<String>? options,
  }) {
    setState(() {
      _tempFieldConfigs[fieldName] = _tempFieldConfigs[fieldName]!.copyWith(
        isShow: isShow,
        isRequired: isRequired,
        hintText: hintText,
        validatorText: validatorText,
        title: title,
        options: options,
      );
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final customerFormNotifier = ref.read(customerFormProvider.notifier);

      // Update all field configs at once
      for (var entry in _tempFieldConfigs.entries) {
        customerFormNotifier.updateFieldConfig(
          entry.key,
          isShow: entry.value.isShow,
          isRequired: entry.value.isRequired,
          title: entry.value.title,
          hintText: entry.value.hintText,
          validatorText: entry.value.validatorText,
          options: entry.value.options,
        );
      }

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      if (mounted) {
        AppFlushbar.success(
          context,
          message: 'Field configurations saved successfully',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        AppFlushbar.error(context, message: 'Failed to save: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Customer & Payment Fields',
        context: context,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.spMin),
              children: [
                Text(
                  'Configure which fields to show in the checkout form',
                  style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
                ),
                if (_hasChanges) ...[
                  SizedBox(height: 8.spMin),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.spMin,
                      vertical: 8.spMin,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        AppIcon(
                          win11IconPath: ImageAssets.win11Info,
                          defaultIcon: Icons.info_outline,
                          color: Colors.orange,
                          size: 16.spMin,
                        ),

                        SizedBox(width: 8.spMin),
                        Expanded(
                          child: Text(
                            'You have unsaved changes',
                            style: TextStyle(
                              fontSize: 12.spMin,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 16.spMin),
                // Add a brand-new field for the checkout form (saved to the
                // same synced config map as the built-in fields).
                OutlinedButton.icon(
                  onPressed: () async {
                    final config = await showAddFieldDialog(context);
                    if (config == null || !context.mounted) return;
                    ref
                        .read(customerFormProvider.notifier)
                        .addFieldConfig(config);
                    setState(() {
                      _tempFieldConfigs = Map<String, FieldConfig>.from(
                        ref.read(customerFormProvider).fieldConfigs,
                      );
                    });
                    if (context.mounted) {
                      AppFlushbar.success(
                        context,
                        message: '"${config.title}" added to the checkout form',
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Field'),
                ),
                SizedBox(height: 16.spMin),
                ..._tempFieldConfigs.entries.map(
                  (entry) => _FieldConfigTile(
                    fieldName: entry.key,
                    fieldConfig: entry.value,
                    onDelete:
                        entry.value.isCustom
                            ? () async {
                              if (!await confirmDeleteField(
                                context,
                                entry.value.title,
                              )) {
                                return;
                              }
                              ref
                                  .read(customerFormProvider.notifier)
                                  .deleteFieldConfig(entry.key);
                              setState(() {
                                _tempFieldConfigs.remove(entry.key);
                              });
                            }
                            : null,
                    onShowChanged: (val) {
                      _updateTempFieldConfig(entry.key, isShow: val);
                    },
                    onRequiredChanged: (val) {
                      _updateTempFieldConfig(entry.key, isRequired: val);
                    },
                    onTitleChanged: (val) {
                      _updateTempFieldConfig(entry.key, title: val);
                    },
                    onHintTextChanged: (val) {
                      _updateTempFieldConfig(entry.key, hintText: val);
                    },
                    onValidatorTextChanged: (val) {
                      _updateTempFieldConfig(entry.key, validatorText: val);
                    },
                    onOptionsChanged: (options) {
                      _updateTempFieldConfig(entry.key, options: options);
                    },
                  ),
                ),
                SizedBox(height: 80.spMin), // Space for floating button
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _hasChanges
              ? FloatingActionButton.extended(
                onPressed: _isSaving ? null : _saveChanges,
                backgroundColor: AppColors.primary,
                icon:
                    _isSaving
                        ? SizedBox(
                          width: 20.spMin,
                          height: 20.spMin,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : AppIcon(
                          win11IconPath: ImageAssets.win11Save,
                          defaultIcon: Icons.save,
                        ),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(color: Colors.white),
                ),
              )
              : null,
    );
  }
}

// Field Config Tile Widget
class _FieldConfigTile extends StatefulWidget {
  final String fieldName;
  final FieldConfig fieldConfig;
  final Function(bool?) onShowChanged;
  final Function(bool?) onRequiredChanged;
  final Function(String) onTitleChanged;
  final Function(String) onHintTextChanged;
  final Function(String) onValidatorTextChanged;

  /// Called when the options of a custom dropdown field are edited.
  final Function(List<String>)? onOptionsChanged;

  /// Non-null only for user-created custom fields — tapping deletes the
  /// field entirely.
  final Future<void> Function()? onDelete;

  const _FieldConfigTile({
    required this.fieldName,
    required this.fieldConfig,
    required this.onShowChanged,
    required this.onRequiredChanged,
    required this.onTitleChanged,
    required this.onHintTextChanged,
    required this.onValidatorTextChanged,
    this.onOptionsChanged,
    this.onDelete,
  });

  @override
  State<_FieldConfigTile> createState() => _FieldConfigTileState();
}

class _FieldConfigTileState extends State<_FieldConfigTile> {
  late TextEditingController titleController;
  late TextEditingController hintTextController;
  late TextEditingController validatorTextController;
  late TextEditingController optionsController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.fieldConfig.title);
    hintTextController = TextEditingController(
      text: widget.fieldConfig.hintText,
    );
    validatorTextController = TextEditingController(
      text: widget.fieldConfig.validatorText,
    );
    optionsController = TextEditingController(
      text: (widget.fieldConfig.options ?? const <String>[]).join('\n'),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    hintTextController.dispose();
    validatorTextController.dispose();
    optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.spMin),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade50,
      child: AppExpansionTile(
        tilePadding: EdgeInsets.symmetric(
          horizontal: 12.spMin,
          vertical: 4.spMin,
        ),
        childrenPadding: EdgeInsets.all(12.spMin),
        title: Row(
          children: [
            AppIcon(
              win11IconPath: ImageAssets.win11Label,
              defaultIcon: Icons.label_outline,
              size: 16.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 12.spMin),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fieldConfig.title,
                    style: TextStyle(
                      fontSize: 14.spMin,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Field: ${widget.fieldName}',
                        style: TextStyle(
                          fontSize: 11.spMin,
                          color: Colors.grey,
                        ),
                      ),
                      if (widget.fieldConfig.isCustom) ...[
                        SizedBox(width: 8.spMin),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.spMin,
                            vertical: 1.spMin,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'Custom',
                            style: TextStyle(
                              fontSize: 9.spMin,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (widget.onDelete != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete field',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: widget.onDelete,
              ),
          ],
        ),
        children: [
          // Show and Required checkboxes
          Column(
            children: [
              CheckboxListTile(
                title: Text('Show', style: TextStyle(fontSize: 13.spMin)),
                value: widget.fieldConfig.isShow,
                onChanged: widget.onShowChanged,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                title: Text('Required', style: TextStyle(fontSize: 13.spMin)),
                value: widget.fieldConfig.isRequired,
                onChanged:
                    widget.fieldConfig.isShow ? widget.onRequiredChanged : null,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ),
          SizedBox(height: 8.spMin),
          CustomTextField(
            label: "Title",
            hintText: "Title",
            controller: titleController,
            onChange: (val) {
              widget.onTitleChanged(val ?? "");
              return null;
            },
          ),
          SizedBox(height: 15.spMin),

          CustomTextField(
            label: "Hint text",
            hintText: "Enter hint text",
            controller: hintTextController,
            onChange: (val) {
              widget.onHintTextChanged(val ?? "");
              return null;
            },
          ),

          SizedBox(height: 15.spMin),

          CustomTextField(
            label: "Validation Error",
            hintText: "Enter Validation Error",
            controller: validatorTextController,
            onChange: (val) {
              widget.onValidatorTextChanged(val ?? "");
              return null;
            },
          ),

          // Editable choices for user-created dropdown fields.
          if (widget.fieldConfig.isCustom &&
              widget.fieldConfig.widgetType == WidgetType.dropdown) ...[
            SizedBox(height: 15.spMin),
            CustomTextField(
              label: "Options (one per line)",
              hintText: "Option 1\nOption 2",
              controller: optionsController,
              maxLines: 4,
              onChange: (val) {
                final options =
                    (val ?? '')
                        .split('\n')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                widget.onOptionsChanged?.call(options);
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}
