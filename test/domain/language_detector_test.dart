import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/language_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const detector = LanguageDetector();

  test('reads Cyrillic as Russian and Latin as English', () {
    expect(detector.detect('Привет, ёлка'), AppLanguage.ru);
    expect(detector.detect('Hello'), AppLanguage.en);
  });

  test('uses the script with more letters', () {
    expect(detector.detect('Привет hello'), AppLanguage.ru);
    expect(detector.detect('Hello мир'), AppLanguage.en);
  });

  test('falls back when the scripts tie or the text has no letters', () {
    expect(
      detector.detect('А A', documentLanguage: AppLanguage.ru),
      AppLanguage.ru,
    );
    expect(detector.detect('А A'), AppLanguage.en);
    expect(
      detector.detect('123 —', documentLanguage: AppLanguage.ru),
      AppLanguage.ru,
    );
    expect(
      const LanguageDetector(fallback: AppLanguage.ru).detect('...'),
      AppLanguage.ru,
    );
  });
}
