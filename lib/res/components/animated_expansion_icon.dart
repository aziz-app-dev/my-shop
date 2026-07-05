import 'package:flutter/material.dart';
import '../assets/image_assets.dart';
import 'app_icon.dart';

class AnimatedExpansionIcon extends StatefulWidget {
  final bool isExpanded;
  final Duration duration;
  final double size;
  final Color? color;

  const AnimatedExpansionIcon({
    super.key,
    required this.isExpanded,
    this.duration = const Duration(milliseconds: 200),
    this.size = 24.0,
    this.color,
  });

  @override
  State<AnimatedExpansionIcon> createState() => _AnimatedExpansionIconState();
}

class _AnimatedExpansionIconState extends State<AnimatedExpansionIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _iconTurns = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    if (widget.isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedExpansionIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _iconTurns,
      child: AppIcon(
        defaultIcon: Icons.keyboard_arrow_down_rounded,
        win11IconPath: ImageAssets.win11ExpandArrow,
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
