import 'app_language.dart';

/// Chooses Russian or English from Cyrillic and Latin letters.
///
/// Text with no letters, or with an equal count of both scripts, uses
/// [documentLanguage] and then [fallback].
final class LanguageDetector {
  const LanguageDetector({this.fallback = AppLanguage.en});

  final AppLanguage fallback;

  AppLanguage detect(String text, {AppLanguage? documentLanguage}) {
    var cyrillic = 0;
    var latin = 0;
    for (final rune in text.runes) {
      if (_isCyrillic(rune)) {
        cyrillic++;
      } else if (_isLatin(rune)) {
        latin++;
      }
    }
    if (cyrillic > latin) return AppLanguage.ru;
    if (latin > cyrillic) return AppLanguage.en;
    return documentLanguage ?? fallback;
  }
}

bool _isCyrillic(int rune) {
  return (rune >= 0x0400 && rune <= 0x04FF) ||
      (rune >= 0x0500 && rune <= 0x052F);
}

bool _isLatin(int rune) {
  return (rune >= 0x0041 && rune <= 0x005A) ||
      (rune >= 0x0061 && rune <= 0x007A) ||
      (rune >= 0x00C0 && rune <= 0x024F);
}
