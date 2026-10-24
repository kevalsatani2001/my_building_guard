import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_strings.dart';
import 'session_guard_service.dart';

class LocalizationService {
  LocalizationService._() {
    currentLocale.addListener(_handleLocaleChanged);
  }
  static final LocalizationService instance = LocalizationService._();

  static const String _prefKey = 'selected_app_language_code';

  /// Default language is Gujarati ('gu')
  final ValueNotifier<Locale> currentLocale = ValueNotifier(const Locale('gu'));

  void _handleLocaleChanged() {
    triggerAppRebuild();
  }

  /// Triggers a live reactive rebuild across the entire element tree without reloading the app
  void triggerAppRebuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        void rebuild(Element el) {
          if (el.mounted) {
            try {
              el.markNeedsBuild();
            } catch (_) {}
            try {
              el.visitChildren(rebuild);
            } catch (_) {}
          }
        }

        final root = WidgetsBinding.instance.rootElement;
        if (root != null && root.mounted) {
          rebuild(root);
        } else {
          final navCtx = rootNavigatorKey.currentContext;
          if (navCtx is Element && navCtx.mounted) {
            rebuild(navCtx);
          }
        }
      } catch (e) {
        debugPrint('Error triggering language rebuild: $e');
      }
    });
  }

  /// Supported languages list
  static const List<Map<String, String>> languages = [
    {
      'code': 'gu',
      'name': 'ગુજરાતી',
      'englishName': 'Gujarati',
      'badge': 'GU',
      'desc': 'ડિફૉલ્ટ સ્થાનિક ભાષા',
    },
    {
      'code': 'hi',
      'name': 'हिन्दी',
      'englishName': 'Hindi',
      'badge': 'HI',
      'desc': 'राष्ट्रभाषा / आसान संचार',
    },
    {
      'code': 'en',
      'name': 'English',
      'englishName': 'English',
      'badge': 'EN',
      'desc': 'Universal Language',
    },
  ];

  /// Initialize stored language preference
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && (savedCode == 'gu' || savedCode == 'hi' || savedCode == 'en')) {
        currentLocale.value = Locale(savedCode);
      } else {
        currentLocale.value = const Locale('gu');
      }
    } catch (e) {
      debugPrint('Error initializing localization: $e');
    }
  }

  /// Change app language and persist
  Future<void> setLocale(String langCode) async {
    if (langCode != 'gu' && langCode != 'hi' && langCode != 'en') return;
    if (currentLocale.value.languageCode == langCode) return;

    currentLocale.value = Locale(langCode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, langCode);
    } catch (e) {
      debugPrint('Error saving language code: $e');
    }
  }

  String get currentCode => currentLocale.value.languageCode;
  bool get isGujarati => currentCode == 'gu';
  bool get isHindi => currentCode == 'hi';
  bool get isEnglish => currentCode == 'en';

  /// Reusable BottomSheet Modal for choosing language
  void showLanguagePicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ValueListenableBuilder<Locale>(
          valueListenable: currentLocale,
          builder: (context, activeLocale, child) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pull Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.translate_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.get('select_language', activeLocale.languageCode),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Select your preferred language / अपनी भाषा चुनें',
                                style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Language Cards
                    ...languages.map((item) {
                      final code = item['code']!;
                      final name = item['name']!;
                      final engName = item['englishName']!;
                      final badge = item['badge']!;
                      final desc = item['desc']!;
                      final isSelected = activeLocale.languageCode == code;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              HapticFeedback.selectionClick();
                              await setLocale(code);
                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                triggerAppRebuild();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      code == 'gu'
                                          ? 'ભાષા સફળતાપૂર્વક બદલાઈ ગઈ છે (ગુજરાતી)'
                                          : (code == 'hi'
                                              ? 'भाषा सफलतापूर्वक बदल दी गई है (हिन्दी)'
                                              : 'Language changed to English'),
                                    ),
                                    backgroundColor: const Color(0xFF0F766E),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFF0FDFA) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  // Badge Pill
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isSelected
                                            ? [const Color(0xFF0F766E), const Color(0xFF14B8A6)]
                                            : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      badge,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF334155),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Name and Desc
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                                color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '($engName)',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          desc,
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Radio Check
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFF0F766E) : Colors.white,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF94A3B8),
                                        width: isSelected ? 2 : 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A compact, elegant language switcher button for any AppBar or Drawer
class LanguageSwitchButton extends StatelessWidget {
  final bool isDark;
  const LanguageSwitchButton({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocalizationService.instance.currentLocale,
      builder: (context, locale, _) {
        final code = locale.languageCode.toUpperCase();
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => LocalizationService.instance.showLanguagePicker(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.translate_rounded,
                    size: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 4.5),
                  Text(
                    code,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
