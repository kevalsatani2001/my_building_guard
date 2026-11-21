import 'package:flutter/material.dart';
import 'package:translator/translator.dart';
import 'localization_service.dart';

/// A 100% free, high-performance automatic translation service.
/// Uses Google's translation engine with in-memory caching and graceful fallback.
/// Converts any input or dynamic text (Notice, Complaints, Visitors, Polls)
/// directly into the user's currently selected app language (Gujarati, Hindi, English).
class AutoTranslationService {
  AutoTranslationService._() {
    // Listen to language changes to notify listening widgets
    LocalizationService.instance.currentLocale.addListener(_onLocaleChanged);
  }

  static final AutoTranslationService instance = AutoTranslationService._();

  final GoogleTranslator _translator = GoogleTranslator();

  /// In-memory cache formatted as: `"$targetLang|$text"` -> translatedText
  final Map<String, String> _cache = {};

  /// Notifier triggered whenever new translations arrive or language changes
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  void _onLocaleChanged() {
    changeNotifier.value++;
  }

  /// Current target language code from active app locale (e.g. 'gu', 'hi', 'en')
  String get activeLanguageCode {
    return LocalizationService.instance.currentLocale.value.languageCode;
  }

  /// Translates [text] to the active app language (or [targetLanguage] if provided).
  /// Returns the original text if empty or if translation fails.
  Future<String> translate(
    String text, {
    String? targetLanguage,
    String from = 'auto',
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return text;

    final target = targetLanguage ?? activeLanguageCode;
    final cacheKey = '$target|$clean';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      final res = await _translator.translate(clean, from: from, to: target);
      final translated = res.text;
      _cache[cacheKey] = translated;
      return translated;
    } catch (e) {
      debugPrint(
        '[AutoTranslation] Error translating "$clean" to "$target": $e',
      );
      return clean; // Fallback to original text gracefully
    }
  }

  /// Immediate synchronous lookup. Returns cached translation if present,
  /// otherwise returns original text and triggers background translation.
  String translateSync(String text, {String? targetLanguage}) {
    final clean = text.trim();
    if (clean.isEmpty) return text;

    final target = targetLanguage ?? activeLanguageCode;
    final cacheKey = '$target|$clean';

    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Trigger async fetch in background
    translate(clean, targetLanguage: target).then((val) {
      if (val != clean) {
        changeNotifier.value++;
      }
    });

    return clean;
  }

  /// Translates a map of fields (e.g., {'title': '...', 'body': '...'})
  Future<Map<String, String>> translateMap(
    Map<String, String> fields, {
    String? targetLanguage,
  }) async {
    final target = targetLanguage ?? activeLanguageCode;
    final results = <String, String>{};

    for (final entry in fields.entries) {
      results[entry.key] = await translate(entry.value, targetLanguage: target);
    }

    return results;
  }

  /// Clear cache if needed
  void clearCache() {
    _cache.clear();
  }
}

/// A drop-in widget replacing standard [Text] that automatically translates
/// dynamic text (from Firebase, user inputs, notices) to the active app language.
class AutoTranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool softWrap;

  const AutoTranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AutoTranslationService.instance.changeNotifier,
      builder: (context, value, child) {
        final translated = AutoTranslationService.instance.translateSync(text);
        return Text(
          translated,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          softWrap: softWrap,
        );
      },
    );
  }
}
