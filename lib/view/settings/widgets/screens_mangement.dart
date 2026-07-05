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

class ScreenManagementSection extends ConsumerWidget {
  final WidgetRef ref;

  const ScreenManagementSection({super.key, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: AppExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
        childrenPadding: EdgeInsets.all(10.h),
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
            TablerIcons.home,
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
        padding: EdgeInsets.all(16.w),
        children: [
          Text(
            'Configure which fields to show in the product form',
            style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
          ),
          SizedBox(height: 16.h),
          ...productFormState.fieldConfigs.entries
              .where((entry) => !['isBackup', 'warranty'].contains(entry.key))
              .map(
                (entry) => _FieldConfigTile(
                  fieldName: entry.key,
                  fieldConfig: entry.value,
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
    // Initialize with current field configs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerFormState = ref.read(customerFormProvider);
      setState(() {
        _tempFieldConfigs = Map<String, FieldConfig>.from(
          customerFormState.fieldConfigs,
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
  }) {
    setState(() {
      _tempFieldConfigs[fieldName] = _tempFieldConfigs[fieldName]!.copyWith(
        isShow: isShow,
        isRequired: isRequired,
        hintText: hintText,
        validatorText: validatorText,
        title: title,
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
              padding: EdgeInsets.all(16.w),
              children: [
                Text(
                  'Configure which fields to show in the checkout form',
                  style: TextStyle(fontSize: 14.spMin, color: Colors.grey),
                ),
                if (_hasChanges) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
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

                        SizedBox(width: 8.w),
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
                SizedBox(height: 16.h),
                ..._tempFieldConfigs.entries.map(
                  (entry) => _FieldConfigTile(
                    fieldName: entry.key,
                    fieldConfig: entry.value,
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
                  ),
                ),
                SizedBox(height: 80.h), // Space for floating button
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
                          width: 20.w,
                          height: 20.h,
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

  const _FieldConfigTile({
    required this.fieldName,
    required this.fieldConfig,
    required this.onShowChanged,
    required this.onRequiredChanged,
    required this.onTitleChanged,
    required this.onHintTextChanged,
    required this.onValidatorTextChanged,
  });

  @override
  State<_FieldConfigTile> createState() => _FieldConfigTileState();
}

class _FieldConfigTileState extends State<_FieldConfigTile> {
  late TextEditingController titleController;
  late TextEditingController hintTextController;
  late TextEditingController validatorTextController;

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
  }

  @override
  void dispose() {
    titleController.dispose();
    hintTextController.dispose();
    validatorTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade900
              : Colors.grey.shade50,
      child: AppExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
        childrenPadding: EdgeInsets.all(12.w),
        title: Row(
          children: [
            AppIcon(
              win11IconPath: ImageAssets.win11Label,
              defaultIcon: Icons.label_outline,
              size: 16.spMin,
              color: AppColors.primary,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fieldConfig.title,
                    style: TextStyle(fontSize: 14.spMin, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Field: ${widget.fieldName}',
                    style: TextStyle(fontSize: 11.spMin, color: Colors.grey),
                  ),
                ],
              ),
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
          SizedBox(height: 8.h),
          CustomTextField(
            label: "Title",
            hintText: "Title",
            controller: titleController,
            onChange: (val) {
              widget.onTitleChanged(val ?? "");
              return null;
            },
          ),
          SizedBox(height: 15.h),

          CustomTextField(
            label: "Hint text",
            hintText: "Enter hint text",
            controller: hintTextController,
            onChange: (val) {
              widget.onHintTextChanged(val ?? "");
              return null;
            },
          ),

          SizedBox(height: 15.h),

          CustomTextField(
            label: "Validation Error",
            hintText: "Enter Validation Error",
            controller: validatorTextController,
            onChange: (val) {
              widget.onValidatorTextChanged(val ?? "");
              return null;
            },
          ),
        ],
      ),
    );
  }
}
