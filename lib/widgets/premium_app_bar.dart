import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
export '../l10n/app_strings.dart';
export '../services/localization_service.dart';
import '../l10n/app_strings.dart';
import '../services/localization_service.dart';
import 'app_back_button.dart';

/// An ultra-premium, distinctive AppBar crafted specifically for the Building Guard app.
/// Uses Flutter's native [AppBar] under the hood to ensure zero RenderFlex overflows across
/// all devices and orientations, while offering tactile squircles, optional module icon chips,
/// dual-line typography, and crisp micro-borders.
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double height;
  final Color backgroundColor;
  final PreferredSizeWidget? bottom;
  final double bottomHeight;
  final bool showLanguageSwitch;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.height = 58.0,
    this.backgroundColor = Colors.white,
    this.bottom,
    this.bottomHeight = 0.0,
    this.showLanguageSwitch = true,
  });

  @override
  Size get preferredSize {
    final effectiveBottomHeight = bottom != null
        ? (bottomHeight > 0 ? bottomHeight : bottom!.preferredSize.height)
        : 1.0;
    return Size.fromHeight(height + effectiveBottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, _, child) {
        final canPop = Navigator.canPop(context);
        final themeAccent = accentColor ?? Theme.of(context).colorScheme.primary;

        Widget? effectiveLeading = leading;
        if (effectiveLeading == null && showBackButton && canPop) {
          effectiveLeading = AppBackButton(onPressed: onBackPressed);
        }

        final effectiveActions = <Widget>[
          ...?actions,
          if (showLanguageSwitch)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Center(child: LanguageSwitchButton()),
            ),
        ];

        return AppBar(
          toolbarHeight: height,
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          leading: effectiveLeading != null ? Center(child: effectiveLeading) : null,
          leadingWidth: effectiveLeading != null ? 54 : null,
          titleSpacing: effectiveLeading != null ? 8 : 16,
          title: (effectiveLeading == null && icon != null)
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: themeAccent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: themeAccent.withValues(alpha: 0.22),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 19,
                        color: themeAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTitleSection()),
                  ],
                )
              : _buildTitleSection(),
          actions: effectiveActions.isNotEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: effectiveActions,
                    ),
                  ),
                ]
              : null,
          bottom: bottom ??
              const PreferredSize(
                preferredSize: Size.fromHeight(1.0),
                child: Divider(
                  height: 1.0,
                  thickness: 1.0,
                  color: Color(0xFFE2E8F0),
                ),
              ),
        );
      },
    );
  }

  Widget _buildTitleSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title.tr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 1.5),
          Text(
            subtitle!.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }
}

/// A tactile squircle action button for [PremiumAppBar] actions
class PremiumAppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final bool showBadge;

  const PremiumAppBarAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? const Color(0xFF0F172A);
    final bg = backgroundColor ?? const Color(0xFFF1F5F9);

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              if (showBadge)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!.tr, child: button);
    }
    return button;
  }
}
