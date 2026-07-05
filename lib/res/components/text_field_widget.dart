// ignore_for_file: deprecated_member_use

import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// ignore_for_file: must_be_immutable, unused_local_variable

import 'package:flutter/services.dart';

import 'app_text_widgrt.dart';

class CustomTextField extends ConsumerWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? label;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool? filled;
  final int? maxLines;
  final String? Function(String?)? validator;
  final String? Function(String?)? onChange;
  final Function(String?)? onFieldSubmitted;
  final IconData? icon;
  final FocusNode? focusNode;
  final TextStyle? hintStyle;
  final bool isSearch;
  final bool? isDense;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? apiError;
  final Color? borderColor;
  final Color? focusedBorder;
  final Color? fillColor;
  final Color? lableColor;
  final double borderRadius;
  final BorderSide? borderSide;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final bool? enabled;
  final IconData? iconPerfix;
  final bool? readOnly;
  final VoidCallback? onTap;
  final BoxConstraints? prefixIconConstraints;
  final EdgeInsetsGeometry? contentPadding;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.focusedBorder,
    this.contentPadding,
    this.isDense,
    this.onTap,
    this.enabled,
    this.iconPerfix,
    this.prefixIconConstraints,
    this.label = '',
    this.readOnly = false,
    this.textInputAction,
    this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.icon,
    this.focusNode,
    this.isSearch = false,
    this.prefixIcon,
    this.suffixIcon,
    this.apiError,
    this.filled,
    this.maxLines = 1,
    this.borderColor,
    this.fillColor,
    this.lableColor,
    this.onChange,
    this.onFieldSubmitted,
    this.hintStyle,
    this.borderRadius = AppSizes.borderRadiusLg,
    this.borderSide,
    this.style,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      spacing: 6.h,

      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        label!.isNotEmpty
            ? mdTextBold(
              text: label,
              color:
                  lableColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dTFieldHintColor
                      : AppColors.lTFieldHintColor),
            )
            : SizedBox.shrink(),
        TextFormField(
          inputFormatters:
              inputFormatters ??
              (keyboardType == TextInputType.number
                  ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))]
                  : null),
          onTap: onTap,
          readOnly: readOnly ?? false,
          enabled: enabled,
          textInputAction: textInputAction,
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: isPassword,
          maxLines: isPassword ? 1 : maxLines,
          cursorColor: AppColors.primary,
          style:
              style ??
              TextStyle(
                fontSize: 12.spMin,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dTFieldHintColor
                        : AppColors.lTFieldHintColor,
              ),
          decoration: InputDecoration(
            isDense: isDense ?? true,
            hintText: hintText,

            labelStyle: TextStyle(fontSize: 12.spMin, color: AppColors.primary),
            hintStyle:
                hintStyle ??
                TextStyle(
                  fontSize: 12.spMin,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppColors.dTFieldHintColor
                          : AppColors.lTFieldHintColor,
                ),
            prefixIcon:
                prefixIcon != null
                    ? Padding(
                      padding: EdgeInsets.only(left: 12.spMin, right: 8.spMin),
                      child: prefixIcon,
                    )
                    : null,
            prefixIconConstraints:
                prefixIconConstraints ??
                BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderSide:
                  borderSide ??
                  BorderSide(
                    width: 1,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.dTFieldHintColor
                            : AppColors.lTFieldHintColor ?? AppColors.primary,
                  ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide:
                  borderSide ??
                  BorderSide(
                    width: 1,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.dTFieldHintColor
                            : AppColors.lTFieldHintColor ?? AppColors.primary,
                  ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide:
                  borderSide ??
                  BorderSide(
                    width: 1,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.dTFieldHintColor
                            : AppColors.lTFieldHintColor ?? AppColors.primary,
                  ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide:
                  borderSide ??
                  BorderSide(
                    width: 1,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppColors.dTFieldHintColor
                            : AppColors.lTFieldHintColor ?? AppColors.primary,
                  ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: borderSide ?? BorderSide(width: 1, color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: borderSide ?? BorderSide(width: 1, color: Colors.red),
            ),
            filled: filled ?? false,
            fillColor:
                fillColor ??
                (Theme.of(context).brightness == Brightness.dark
                    ? AppColors.dTFieldColor
                    : AppColors.lTFieldColor),

            contentPadding:
                contentPadding ??
                EdgeInsets.symmetric(
                  vertical: AppSizes.tFVerPadding + 4.spMin,
                  horizontal: AppSizes.tFHorPadding.spMin,
                ),

            // constraints: BoxConstraints(minWidth: 20.w, minHeight: 2),
            // prefixIconConstraints:
            //     prefixIconConstraints ??
            //     BoxConstraints(minWidth: 0.spMin, minHeight: 2),
          ),
          validator: validator,
          onChanged: onChange,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final FontWeight? labelSize;
  final String hintText;
  final String? Function(T?)? validator;
  final List<T?> items; // Allow null items
  final List<String>? displayItems;
  final T? value;
  final void Function(T?)? onChanged;
  final bool? filled;
  final bool? isDense;
  final bool? isExpanded;
  final Color? fillColor;
  final Color? lableColor;
  final BorderSide? borderSide;
  final double borderRadius;
  final Color? borderColor;
  final Widget? prefixIcon;

  const AppDropdown({
    super.key,
    this.labelSize,
    this.borderColor,
    this.validator,
    required this.label,
    required this.hintText,
    required this.items,
    this.displayItems,
    required this.value,
    required this.onChanged,
    this.filled,
    this.lableColor,
    this.prefixIcon,
    this.fillColor,
    this.borderRadius = AppSizes.borderRadiusLg,
    this.borderSide,
    this.isDense,
    this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 6.h,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mdTextBold(
          text: label,
          color:
              lableColor ??
              (Theme.of(context).brightness == Brightness.dark
                  ? AppColors.dTFieldHintColor
                  : AppColors.lTFieldHintColor),
        ),
        SizedBox(
          height: 35.h,
          child: DropdownButtonFormField<T?>(
            validator: validator,
            padding: EdgeInsets.zero,
            isExpanded: isExpanded ?? false,
            isDense: isDense ?? true,
            dropdownColor:
                (Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white),
            initialValue: value,
            style: TextStyle(
              fontSize: 12.spMin,
              color:
                  (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dTFieldHintColor
                      : AppColors.lTFieldHintColor),
            ),
            hint: Text(
              hintText,
              style: TextStyle(
                fontSize: 12.spMin,
                color:
                    (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dTFieldHintColor
                        : AppColors.lTFieldHintColor),
              ),
            ),

            onChanged: onChanged,
            items:
                items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final displayText =
                      displayItems != null && index < displayItems!.length
                          ? displayItems![index]
                          : item?.toString() ?? '';
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(displayText),
                  );
                }).toList(),
            decoration: InputDecoration(
              filled: filled ?? false,
              prefixIcon:
                  prefixIcon != null
                      ? Padding(
                        padding: EdgeInsets.only(
                          left: 12.spMin,
                          right: 8.spMin,
                        ),
                        child: prefixIcon,
                      )
                      : null,
              prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              labelStyle: TextStyle(
                fontSize: 12.spMin,
                color: AppColors.primary,
              ),
              hintStyle: TextStyle(
                fontSize: 12.spMin,
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppColors.dTFieldHintColor
                        : AppColors.lTFieldHintColor,
              ),

              // suffixIconConstraints: BoxConstraints(
              //   minWidth: 10.w,
              //   minHeight: 2.h,
              // ),
              fillColor:
                  fillColor ??
                  (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dTFieldColor
                      : AppColors.lTFieldColor),
              // All borders will be grey
              border: OutlineInputBorder(
                borderSide:
                    borderSide ??
                    BorderSide(
                      width: 1,
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.dTFieldHintColor
                              : AppColors.lTFieldHintColor ??
                                  AppColors.primary),
                    ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide:
                    borderSide ??
                    BorderSide(
                      width: 1,
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.dTFieldHintColor
                              : AppColors.lTFieldHintColor ??
                                  AppColors.primary),
                    ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide:
                    borderSide ??
                    BorderSide(
                      width: 1,
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.dTFieldHintColor
                              : AppColors.lTFieldHintColor ??
                                  AppColors.primary),
                    ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide:
                    borderSide ??
                    BorderSide(
                      width: 1,
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                              ? AppColors.dTFieldHintColor
                              : AppColors.lTFieldHintColor ??
                                  AppColors.primary),
                    ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide:
                    borderSide ?? BorderSide(width: 1, color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide:
                    borderSide ?? BorderSide(width: 1, color: Colors.red),
              ),

              // prefixIconConstraints: BoxConstraints(
              //   minWidth: 20.w,
              //   minHeight: 10.h,
              // ),
              // constraints: BoxConstraints(minWidth: 20.w, minHeight: 2),
              contentPadding: EdgeInsets.symmetric(
                vertical: AppSizes.tFVerPadding.spMin,
                horizontal: AppSizes.tFHorPadding.spMin,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
