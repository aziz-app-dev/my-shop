import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'animated_expansion_icon.dart';

class AppExpansionTile extends StatefulWidget {
  final Widget title;
  final List<Widget> children;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? tilePadding;
  final EdgeInsetsGeometry? childrenPadding;
  final ValueChanged<bool>? onExpansionChanged;

  const AppExpansionTile({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
    this.tilePadding,
    this.childrenPadding,
    this.onExpansionChanged,
  });

  @override
  State<AppExpansionTile> createState() => _AppExpansionTileState();
}

class _AppExpansionTileState extends State<AppExpansionTile> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: widget.initiallyExpanded,
      tilePadding: widget.tilePadding ?? EdgeInsets.symmetric(horizontal: 16.w),
      childrenPadding: widget.childrenPadding ?? EdgeInsets.all(16.h),
      title: widget.title,
      trailing: AnimatedExpansionIcon(
        isExpanded: _isExpanded,
        size: 24.spMin,
      ),
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded = expanded;
        });
        widget.onExpansionChanged?.call(expanded);
      },
      children: widget.children,
    );
  }
}
