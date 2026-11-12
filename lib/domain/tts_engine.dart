import 'app_language.dart';

enum TtsUtteranceEnd { completed, paused, cancelled, failed }

final class TtsSpeakResult {
  const TtsSpeakResult(this.end, {this.message});

  final TtsUtteranceEnd end;
  final String? message;
}

/// Platform speech engine used by the reader queue.
///
/// [speak] finishes when the utterance completes, pauses, is cancelled, or
/// fails. [resume] continues the utterance paused by [pause].
abstract interface class TtsEngine {
  Future<void> warmup();

  Future<bool> isAvailable(AppLanguage language);

  Future<void> setRate(double rate);

  Future<TtsSpeakResult> speak(String text, {required AppLanguage language});

  Future<void> pause();

  Future<TtsSpeakResult> resume();

  Future<void> stop();
}

final class TtsFailure implements Exception {
  const TtsFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
