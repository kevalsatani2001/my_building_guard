import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A unique, tactile premium back button used across the entire Society Guard app.
/// Featuring a sleek rounded squircle, micro-border, adaptive contrast and haptic feedback.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = color ?? IconTheme.of(context).color ?? const Color(0xFF0F172A);
    final isLightIcon = effectiveIconColor.computeLuminance() > 0.45;

    final effectiveBg = backgroundColor ??
        (isLightIcon ? Colors.white.withValues(alpha: 0.18) : const Color(0xFFF1F5F9));
    final effectiveBorder = borderColor ??
        (isLightIcon ? Colors.white.withValues(alpha: 0.28) : const Color(0xFFE2E8F0));

    return Tooltip(
      message: 'પાછા જાઓ',
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              if (onPressed != null) {
                onPressed!();
              } else {
                Navigator.maybePop(context);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: effectiveBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: effectiveBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: effectiveIconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
