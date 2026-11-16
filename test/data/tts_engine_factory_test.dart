import 'package:document_to_podcast/data/memory_audio_cache.dart';
import 'package:document_to_podcast/data/quality_speech_web.dart';
import 'package:document_to_podcast/data/routing_tts_engine.dart';
import 'package:document_to_podcast/data/system_tts_engine.dart';
import 'package:document_to_podcast/data/tts_engine_factory.dart';
import 'package:document_to_podcast/domain/playback_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_model_downloader.dart';

void main() {
  test('system speech uses the system engine', () {
    final engine = AppTtsEngineFactory(voices: MemoryModelDownloader())
        .create(SpeechEngine.system);

    expect(engine, isA<SystemTtsEngine>());
  });

  test(
    'quality speech falls back to system speech when a voice is missing',
    () {
      final engine = AppTtsEngineFactory(voices: MemoryModelDownloader())
          .create(SpeechEngine.quality);

      expect(engine, isA<RoutingTtsEngine>());
    },
  );

  test('browsers keep quality speech on the system engine', () {
    final engine = createQualityEngine(
      MemoryModelDownloader(),
      MemoryAudioCache(),
    );

    expect(engine, isA<SystemTtsEngine>());
  });
}
