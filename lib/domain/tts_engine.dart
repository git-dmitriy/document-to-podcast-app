import 'app_language.dart';

enum TtsUtteranceEnd { completed, paused, cancelled, failed }

final class TtsSpeakResult {
  const TtsSpeakResult(this.end, {this.message});

  final TtsUtteranceEnd end;
  final String? message;
}

/// Character range inside the text passed to [TtsEngine.speak].
final class TtsUtteranceProgress {
  const TtsUtteranceProgress({required this.start, required this.end});

  final int start;
  final int end;

  @override
  bool operator ==(Object other) {
    return other is TtsUtteranceProgress &&
        other.start == start &&
        other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

typedef TtsProgressHandler = void Function(TtsUtteranceProgress progress);

/// Platform speech engine used by the reader queue.
///
/// [speak] finishes when the utterance completes, pauses, is cancelled, or
/// fails. [resume] continues the utterance paused by [pause].
///
/// Engines that can report spoken ranges call [onProgress] while an utterance
/// is active. Unsupported engines may ignore it.
abstract interface class TtsEngine {
  Future<void> warmup();

  Future<bool> isAvailable(AppLanguage language);

  Future<void> setRate(double rate);

  Future<TtsSpeakResult> speak(
    String text, {
    required AppLanguage language,
    TtsProgressHandler? onProgress,
  });

  Future<void> pause();

  Future<TtsSpeakResult> resume({TtsProgressHandler? onProgress});

  Future<void> stop();

  Future<void> dispose();
}

final class TtsFailure implements Exception {
  const TtsFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
