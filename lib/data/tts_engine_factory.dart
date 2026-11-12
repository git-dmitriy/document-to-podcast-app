import '../domain/playback_settings.dart';
import '../domain/tts_engine.dart';
import 'system_tts_engine.dart';
import 'unavailable_quality_engine.dart';

abstract interface class TtsEngineFactory {
  TtsEngine create(SpeechEngine engine);
}

final class AppTtsEngineFactory implements TtsEngineFactory {
  const AppTtsEngineFactory();

  @override
  TtsEngine create(SpeechEngine engine) {
    return switch (engine) {
      SpeechEngine.system => SystemTtsEngine(),
      SpeechEngine.quality => const UnavailableQualityEngine(),
    };
  }
}
