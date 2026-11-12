import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/speech_plan.dart';
import 'package:document_to_podcast/domain/speech_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recognizes Russian and English language codes', () {
    expect(AppLanguage.byCode('ru'), AppLanguage.ru);
    expect(AppLanguage.byCode('en'), AppLanguage.en);
    expect(AppLanguage.byCode('fr'), isNull);
  });

  test('compares speech plans by segment value', () {
    final plan = SpeechPlan(
      segments: const [
        SpeechSegment(
          text: 'Title',
          language: AppLanguage.ru,
          kind: SpeechSegmentKind.heading,
        ),
      ],
    );
    final same = SpeechPlan(
      segments: const [
        SpeechSegment(
          text: 'Title',
          language: AppLanguage.ru,
          kind: SpeechSegmentKind.heading,
        ),
      ],
    );
    final different = SpeechPlan(
      segments: const [
        SpeechSegment(
          text: 'Title',
          language: AppLanguage.en,
          kind: SpeechSegmentKind.paragraph,
        ),
      ],
    );

    expect(plan, same);
    expect(plan, isNot(different));
  });
}
