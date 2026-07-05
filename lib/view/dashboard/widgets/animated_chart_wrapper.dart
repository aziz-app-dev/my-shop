import 'package:flutter/material.dart';

/// A wrapper widget that provides animation from 0 to 1 for chart values.
/// Use the [animationValue] in the builder to multiply chart data values.
class AnimatedChartWrapper extends StatefulWidget {
  final Widget Function(double animationValue) builder;
  final Duration duration;
  final Curve curve;
  final bool animate;

  const AnimatedChartWrapper({
    super.key,
    required this.builder,
    this.duration = const Duration(milliseconds: 800),
    this.curve = Curves.easeOutCubic,
    this.animate = true,
  });

  @override
  State<AnimatedChartWrapper> createState() => _AnimatedChartWrapperState();
}

class _AnimatedChartWrapperState extends State<AnimatedChartWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    if (widget.animate) {
      // Start animation after the first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return widget.builder(_animation.value);
      },
    );
  }
}

/// A widget that animates a numeric value from 0 to its target.
/// Useful for summary cards and counters.
class AnimatedValue extends StatefulWidget {
  final double value;
  final Duration duration;
  final Curve curve;
  final Widget Function(double animatedValue) builder;

  const AnimatedValue({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 1000),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedValue> createState() => _AnimatedValueState();
}

class _AnimatedValueState extends State<AnimatedValue>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _updateAnimation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  void _updateAnimation() {
    _animation = Tween<double>(
      begin: _previousValue,
      end: widget.value,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
  }

  @override
  void didUpdateWidget(AnimatedValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = _animation.value;
      _controller.reset();
      _updateAnimation();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return widget.builder(_animation.value);
      },
    );
  }
}
