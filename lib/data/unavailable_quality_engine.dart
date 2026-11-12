import '../domain/app_language.dart';
import '../domain/tts_engine.dart';

/// Quality files can be downloaded before the Piper player is connected.
final class UnavailableQualityEngine implements TtsEngine {
  const UnavailableQualityEngine();

  static const reason = 'Quality speech is not available yet.';

  @override
  Future<void> warmup() async {}

  @override
  Future<bool> isAvailable(AppLanguage language) async => false;

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<TtsSpeakResult> speak(
    String text, {
    required AppLanguage language,
  }) async {
    return const TtsSpeakResult(TtsUtteranceEnd.failed, message: reason);
  }

  @override
  Future<void> pause() async {}

  @override
  Future<TtsSpeakResult> resume() async {
    return const TtsSpeakResult(TtsUtteranceEnd.cancelled, message: reason);
  }

  @override
  Future<void> stop() async {}
}
