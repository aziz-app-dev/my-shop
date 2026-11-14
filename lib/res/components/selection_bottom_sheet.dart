// Reusable picker shown as a modal bottom sheet (mobile-friendly,
// keyboard-openable everywhere): a filter box on top, the selectable names,
// and an "add new" option that creates and selects a new entry in one step.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../colors/app_color.dart';

/// Opens a bottom sheet that lists [names] with a live search box. Tapping a
/// name pops with it; tapping the add-new button swaps the sheet into a small
/// form whose save calls [onAddNew] — on success ([onAddNew] returns null)
/// the sheet pops with the created name instead.
Future<String?> showSelectionBottomSheet(
  BuildContext context, {
  required String title,
  required List<String> names,
  required String addNewLabel,
  required Future<String?> Function(String name) onAddNew,
  String? selectedName,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).brightness == Brightness.dark
            ? AppColors.dCardColor
            : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder:
        (sheetContext) => _SelectionSheet(
          title: title,
          names: names,
          addNewLabel: addNewLabel,
          onAddNew: onAddNew,
          selectedName: selectedName,
        ),
  );
}

class _SelectionSheet extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.names,
    required this.addNewLabel,
    required this.onAddNew,
    this.selectedName,
  });

  final String title;
  final List<String> names;
  final String addNewLabel;
  final Future<String?> Function(String name) onAddNew;
  final String? selectedName;

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _newNameController = TextEditingController();
  final FocusNode _queryFocus = FocusNode();

  String _query = '';

  /// Whether the add-new panel is shown instead of the search + list.
  bool _adding = false;

  /// While [onAddNew] is saving.
  bool _saving = false;

  /// Error text from [onAddNew], shown in the add-new panel.
  String? _addError;

  @override
  void dispose() {
    _queryController.dispose();
    _newNameController.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  Future<void> _confirmNew() async {
    final name = _newNameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _saving = true;
      _addError = null;
    });

    String? error;
    try {
      error = await widget.onAddNew(name);
    } catch (e) {
      error = 'Could not save: $e';
    }
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _saving = false;
        _addError = error;
      });
      return;
    }

    // Success — return the created name so the caller selects it.
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor =
        isDark ? AppColors.dTFieldHintColor : AppColors.lTFieldHintColor;

    final filtered =
        widget.names
            .where((n) => n.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Padding(
      // Keep the content above the keyboard (search / new-name field).
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: 0.7.sh),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber + title + close
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 8.w, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16.spMin,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, size: 20.spMin),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 8.h, thickness: 0.5),

              if (_adding) ...[
                // ---- Add-new panel ----
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_addError != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            _addError!,
                            style: TextStyle(
                              fontSize: 12.spMin,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newNameController,
                              autofocus: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _confirmNew(),
                              style: TextStyle(fontSize: 14.spMin),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: widget.addNewLabel,
                                hintStyle: TextStyle(
                                  fontSize: 12.spMin,
                                  color: hintColor,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          _saving
                              ? SizedBox(
                                width: 26.w,
                                height: 26.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primary,
                                  ),
                                ),
                              )
                              : ElevatedButton(
                                onPressed: _confirmNew,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 12.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                ),
                                child: Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 13.spMin,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                        ],
                      ),
                      TextButton(
                        onPressed:
                            _saving
                                ? null
                                : () => setState(() => _adding = false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13.spMin,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // ---- Search box ----
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: TextField(
                    controller: _queryController,
                    focusNode: _queryFocus,
                    onChanged: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 14.spMin),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: Icon(
                        Icons.search,
                        size: 20.spMin,
                        color: hintColor,
                      ),
                      hintText: 'Search ${widget.title.toLowerCase()}...',
                      hintStyle: TextStyle(
                        fontSize: 12.spMin,
                        color: hintColor,
                      ),
                      suffixIcon:
                          _query.isNotEmpty
                              ? IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(
                                  Icons.close,
                                  size: 16.spMin,
                                  color: hintColor,
                                ),
                                onPressed: () {
                                  _queryController.clear();
                                  setState(() => _query = '');
                                  _queryFocus.requestFocus();
                                },
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                // ---- Names ----
                Flexible(
                  child:
                      filtered.isEmpty
                          ? Padding(
                            padding: EdgeInsets.all(24.h),
                            child: Text(
                              _query.isEmpty
                                  ? 'Nothing added yet — use the button below.'
                                  : 'No match for "$_query"',
                              style: TextStyle(
                                fontSize: 13.spMin,
                                color: hintColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.only(bottom: 8.h),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final name = filtered[index];
                              final isSelected =
                                  widget.selectedName != null &&
                                  name == widget.selectedName;
                              return ListTile(
                                dense: true,
                                leading:
                                    isSelected
                                        ? Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 20.spMin,
                                        )
                                        : null,
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 14.spMin,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                    color:
                                        isSelected ? AppColors.primary : null,
                                  ),
                                ),
                                onTap: () => Navigator.pop(context, name),
                              );
                            },
                          ),
                ),
                // ---- Add-new button ----
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed:
                          () => setState(() {
                            _adding = true;
                            _addError = null;
                          }),
                      icon: Icon(Icons.add, size: 18.spMin),
                      label: Text(
                        widget.addNewLabel,
                        style: TextStyle(
                          fontSize: 13.spMin,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 10.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
