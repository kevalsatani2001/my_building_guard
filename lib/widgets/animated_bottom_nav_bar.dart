import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Item model for [FloatingGlassmorphicNavBar]
class FloatingNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final int? badgeCount;
  final Color? badgeColor;
  final Color? accentColor;

  const FloatingNavItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    this.badgeCount,
    this.badgeColor,
    this.accentColor,
  });
}

/// Ultra-Luxury Sliding Floating Glassmorphic Animated Navigation Bar
///
/// Features:
/// - Smooth spring-animated sliding pill indicator that physically glides between tabs
/// - Neon aura drop shadow on the active capsule
/// - Frosted glassmorphism via [BackdropFilter] with subtle top highlight border
/// - Pulsing glowing badge for dynamic notifications (e.g. pending visitors)
/// - Haptic feedback integration on tap
/// - Adaptive light and dark styling with role-accent gradients
class FloatingGlassmorphicNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;
  final bool isDark;
  final Color? primaryColor;
  final double bottomPadding;

  const FloatingGlassmorphicNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isDark = false,
    this.primaryColor,
    this.bottomPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = isDark || theme.brightness == Brightness.dark;
    final defaultAccent = primaryColor ??
        (isDarkMode ? const Color(0xFF14B8A6) : const Color(0xFF0F766E));

    final safeIndex = currentIndex.clamp(0, items.isEmpty ? 0 : items.length - 1);
    final activeItem = items.isNotEmpty ? items[safeIndex] : null;
    final activeAccent = activeItem?.accentColor ?? defaultAccent;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding),
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              // Deep ambient elevation shadow
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withValues(alpha: 0.6)
                    : const Color(0xFF0F172A).withValues(alpha: 0.14),
                blurRadius: 32,
                spreadRadius: -2,
                offset: const Offset(0, 12),
              ),
              // Dynamic colored glow behind the active bar
              BoxShadow(
                color: activeAccent.withValues(alpha: isDarkMode ? 0.22 : 0.14),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDarkMode
                        ? [
                            const Color(0xFF1E293B).withValues(alpha: 0.88),
                            const Color(0xFF0F172A).withValues(alpha: 0.95),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.94),
                            const Color(0xFFF8FAFC).withValues(alpha: 0.98),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.9),
                    width: 1.5,
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final totalWidth = constraints.maxWidth;
                    final itemWidth = totalWidth / items.length;
                    const pillMarginH = 3.0;
                    final pillWidth = itemWidth - (pillMarginH * 2);
                    final pillLeft = (safeIndex * itemWidth) + pillMarginH;

                    return Stack(
                      children: [
                        // 1. Sliding Glowing Gradient Pill
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutBack,
                          left: pillLeft,
                          top: 4,
                          bottom: 4,
                          width: pillWidth,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  activeAccent,
                                  activeAccent.withValues(alpha: 0.82),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: activeAccent.withValues(
                                    alpha: isDarkMode ? 0.48 : 0.35,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 2. Interactive Navigation Items
                        Row(
                          children: List.generate(items.length, (index) {
                            final item = items[index];
                            final isSelected = safeIndex == index;

                            return Expanded(
                              child: _SlidingNavItem(
                                item: item,
                                isSelected: isSelected,
                                activeAccent: activeAccent,
                                isDarkMode: isDarkMode,
                                onTap: () {
                                  if (safeIndex != index) {
                                    HapticFeedback.selectionClick();
                                    onTap(index);
                                  }
                                },
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlidingNavItem extends StatefulWidget {
  final FloatingNavItem item;
  final bool isSelected;
  final Color activeAccent;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _SlidingNavItem({
    required this.item,
    required this.isSelected,
    required this.activeAccent,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  State<_SlidingNavItem> createState() => _SlidingNavItemState();
}

class _SlidingNavItemState extends State<_SlidingNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.item.badgeCount != null && widget.item.badgeCount! > 0) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _SlidingNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasBadge = widget.item.badgeCount != null && widget.item.badgeCount! > 0;
    if (hasBadge && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!hasBadge && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unselectedColor =
        widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final hasBadge = widget.item.badgeCount != null && widget.item.badgeCount! > 0;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Animated Icon with Scale & Color Transition
                AnimatedScale(
                  scale: widget.isSelected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    widget.isSelected
                        ? (widget.item.activeIcon ?? widget.item.icon)
                        : widget.item.icon,
                    color: widget.isSelected ? Colors.white : unselectedColor,
                    size: 22,
                  ),
                ),

                // Pulsing Badge Indicator
                if (hasBadge)
                  Positioned(
                    top: -6,
                    right: -11,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final badgeColor =
                            widget.item.badgeColor ?? const Color(0xFFEF4444);
                        return Transform.scale(
                          scale: 1.0 + (_pulseCtrl.value * 0.12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: badgeColor.withValues(
                                    alpha: 0.5 + (_pulseCtrl.value * 0.3),
                                  ),
                                  blurRadius: 8 + (_pulseCtrl.value * 4),
                                  spreadRadius: 0.5,
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              widget.item.badgeCount! > 99
                                  ? '99+'
                                  : '${widget.item.badgeCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),

            // Animated Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: widget.isSelected ? 11 : 10,
                fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w600,
                color: widget.isSelected ? Colors.white : unselectedColor,
                letterSpacing: widget.isSelected ? -0.2 : 0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}
