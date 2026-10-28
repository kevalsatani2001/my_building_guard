import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Animated Number & Currency Counter
///
/// Smoothly animates numbers and financial figures from 0 to the target value
/// whenever data arrives or changes.
class AnimatedCountUpText extends StatefulWidget {
  final num value;
  final Duration duration;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final bool isCurrency;
  final int decimalPlaces;
  final Curve curve;

  const AnimatedCountUpText({
    super.key,
    required this.value,
    this.duration = const Duration(milliseconds: 900),
    this.style,
    this.prefix = '',
    this.suffix = '',
    this.isCurrency = false,
    this.decimalPlaces = 0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCountUpText> createState() => _AnimatedCountUpTextState();
}

class _AnimatedCountUpTextState extends State<AnimatedCountUpText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  num _fromValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0.0, end: widget.value.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _fromValue = _animation.value;
      _animation = Tween<double>(
        begin: _fromValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double val) {
    if (widget.isCurrency) {
      final formatter = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '',
        decimalDigits: widget.decimalPlaces,
      );
      return formatter.format(val).trim();
    } else {
      if (widget.decimalPlaces > 0) {
        return val.toStringAsFixed(widget.decimalPlaces);
      }
      return val.round().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final formatted = _format(_animation.value);
        return Text(
          '${widget.prefix}$formatted${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

/// Staggered Entrance Animation
///
/// Wraps list items or cards so they slide smoothly upwards and fade in,
/// staggered by their list index for a luxurious cascading appearance.
class StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delayStep;
  final Duration duration;
  final double slideOffset;
  final Curve curve;

  const StaggeredEntrance({
    super.key,
    required this.index,
    required this.child,
    this.delayStep = const Duration(milliseconds: 45),
    this.duration = const Duration(milliseconds: 420),
    this.slideOffset = 24.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    // Stagger delay based on index (capped at max 400ms to keep app snappy)
    final delayMs = math.min(widget.index * widget.delayStep.inMilliseconds, 400);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Pulsing Status Dot & Radar Wave
///
/// Adds a breathing radar wave effect around live and urgent badges
/// (e.g. "લાઇવ ગેટ", "પેન્ડિંગ અતિથિ", "ઇમરજન્સી SOS").
class PulsingStatusDot extends StatefulWidget {
  final Color color;
  final double size;
  final bool animate;

  const PulsingStatusDot({
    super.key,
    this.color = const Color(0xFF10B981),
    this.size = 8.0,
    this.animate = true,
  });

  @override
  State<PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<PulsingStatusDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulsingStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: widget.size * 2.4,
          height: widget.size * 2.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer radar ripple
              Transform.scale(
                scale: 1.0 + (_controller.value * 1.4),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(
                      alpha: math.max(0.0, 0.45 * (1.0 - _controller.value)),
                    ),
                  ),
                ),
              ),
              // Inner glowing core
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Pulsing Live Badge Pill
///
/// An ultra-modern badge containing a pulsing radar dot, icon, and label.
class PulsingLiveBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  const PulsingLiveBadge({
    super.key,
    required this.label,
    this.color = const Color(0xFF10B981),
    this.icon,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsingStatusDot(color: color, size: 7),
          const SizedBox(width: 6),
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: textStyle ??
                TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.1,
                ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Micro-Spring Bounce Wrapper
///
/// Adds an elastic tactile response when tapping any card or button.
class InteractiveBounce extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const InteractiveBounce({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.96,
    this.duration = const Duration(milliseconds: 140),
  });

  @override
  State<InteractiveBounce> createState() => _InteractiveBounceState();
}

class _InteractiveBounceState extends State<InteractiveBounce>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Shimmer Skeleton Loader
///
/// Smooth animated gradient sheen simulating content loading.
class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final bool isDark;

  const ShimmerLoading({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.isDark = false,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = widget.isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment(-1.5 + (_controller.value * 3.0), -0.3),
              end: Alignment(-0.5 + (_controller.value * 3.0), 0.3),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}
