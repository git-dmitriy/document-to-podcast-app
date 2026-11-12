import 'package:document_to_podcast/data/system_tts_engine.dart';
import 'package:document_to_podcast/data/tts_engine_factory.dart';
import 'package:document_to_podcast/data/unavailable_quality_engine.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/playback_settings.dart';
import 'package:document_to_podcast/domain/tts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('system speech uses the system engine', () {
    final engine = const AppTtsEngineFactory().create(SpeechEngine.system);

    expect(engine, isA<SystemTtsEngine>());
  });

  test(
    'quality speech stays unavailable until the player is connected',
    () async {
      final engine = const AppTtsEngineFactory().create(SpeechEngine.quality);

      expect(engine, isA<UnavailableQualityEngine>());
      expect(await engine.isAvailable(AppLanguage.en), isFalse);
      final spoken = await engine.speak('Hello', language: AppLanguage.en);
      expect(spoken.end, TtsUtteranceEnd.failed);
      expect(spoken.message, UnavailableQualityEngine.reason);
      final resumed = await engine.resume();
      expect(resumed.end, TtsUtteranceEnd.cancelled);
      expect(resumed.message, UnavailableQualityEngine.reason);
    },
  );
}
