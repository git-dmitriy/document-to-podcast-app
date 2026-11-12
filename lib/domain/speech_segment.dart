import 'app_language.dart';

enum SpeechSegmentKind { heading, paragraph, listItem, skip }

final class SpeechSegment {
  const SpeechSegment({
    required this.text,
    required this.language,
    required this.kind,
  });

  final String text;
  final AppLanguage language;
  final SpeechSegmentKind kind;

  @override
  bool operator ==(Object other) {
    return other is SpeechSegment &&
        other.text == text &&
        other.language == language &&
        other.kind == kind;
  }

  @override
  int get hashCode => Object.hash(text, language, kind);
}
