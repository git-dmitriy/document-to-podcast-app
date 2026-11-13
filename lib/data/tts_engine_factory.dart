import '../domain/playback_settings.dart';
import '../domain/tts_engine.dart';
import 'model_downloader.dart';
import 'quality_speech_io.dart'
    if (dart.library.html) 'quality_speech_web.dart'
    as quality_speech;
import 'system_tts_engine.dart';

abstract interface class TtsEngineFactory {
  TtsEngine create(SpeechEngine engine);
}

final class AppTtsEngineFactory implements TtsEngineFactory {
  AppTtsEngineFactory({required this._voices});

  final ModelDownloader _voices;

  @override
  TtsEngine create(SpeechEngine engine) {
    return switch (engine) {
      SpeechEngine.system => SystemTtsEngine(),
      SpeechEngine.quality => quality_speech.createQualityEngine(_voices),
    };
  }
}
