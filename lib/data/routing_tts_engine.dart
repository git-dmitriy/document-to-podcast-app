import '../domain/app_language.dart';
import '../domain/tts_engine.dart';

/// Uses quality speech when the voice is installed and system speech otherwise.
final class RoutingTtsEngine implements TtsEngine {
  RoutingTtsEngine({required this._quality, required this._system});

  final TtsEngine _quality;
  final TtsEngine _system;
  TtsEngine? _active;

  @override
  Future<void> warmup() async {
    await _quality.warmup();
    await _system.warmup();
  }

  @override
  Future<bool> isAvailable(AppLanguage language) async {
    if (await _quality.isAvailable(language)) return true;
    return _system.isAvailable(language);
  }

  @override
  Future<void> setRate(double rate) async {
    await _quality.setRate(rate);
    await _system.setRate(rate);
  }

  @override
  Future<TtsSpeakResult> speak(
    String text, {
    required AppLanguage language,
  }) async {
    final qualityReady = await _quality.isAvailable(language);
    final engine = qualityReady ? _quality : _system;
    _active = engine;
    return engine.speak(text, language: language);
  }

  @override
  Future<void> pause() async {
    final active = _active;
    if (active == null) return;
    await active.pause();
  }

  @override
  Future<TtsSpeakResult> resume() {
    final active = _active;
    if (active == null) {
      return Future.value(const TtsSpeakResult(TtsUtteranceEnd.cancelled));
    }
    return active.resume();
  }

  @override
  Future<void> stop() async {
    final active = _active;
    if (active == null) return;
    await active.stop();
  }

  @override
  Future<void> dispose() async {
    await _quality.dispose();
    await _system.dispose();
  }
}
