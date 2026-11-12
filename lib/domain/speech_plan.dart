import 'speech_segment.dart';

final class SpeechPlan {
  SpeechPlan({required List<SpeechSegment> segments})
    : segments = List.unmodifiable(segments);

  final List<SpeechSegment> segments;

  @override
  bool operator ==(Object other) {
    if (other is! SpeechPlan || other.segments.length != segments.length) {
      return false;
    }
    for (var index = 0; index < segments.length; index++) {
      if (other.segments[index] != segments[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(segments);
}
