import 'dart:async';

import 'package:document_to_podcast/data/model_downloader.dart';
import 'package:document_to_podcast/data/piper_tts_engine.dart';
import 'package:document_to_podcast/data/piper_voice.dart';
import 'package:document_to_podcast/data/routing_tts_engine.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/tts_engine.dart';
import 'package:document_to_podcast/domain/voice_package.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_tts_engine.dart';
import '../support/memory_model_downloader.dart';

void main() {
  test('speaks each sentence with the voice for that language', () async {
    final client = _Client();
    final host = _Host(client);
    final voices = MemoryModelDownloader()
      ..models[VoiceId.lessac] = const InstalledVoiceModel(
        modelPath: 'en.onnx',
        configPath: 'en.json',
      )
      ..models[VoiceId.irina] = const InstalledVoiceModel(
        modelPath: 'ru.onnx',
        configPath: 'ru.json',
      );
    final engine = PiperTtsEngine(voices: voices, host: host);
    addTearDown(engine.dispose);

    final english = await engine.speak('One. Two.', language: AppLanguage.en);
    final russian = await engine.speak('Раз.', language: AppLanguage.ru);

    expect(english.end, TtsUtteranceEnd.completed);
    expect(russian.end, TtsUtteranceEnd.completed);
    expect(client.spoken, ['One.', 'Two.', 'Раз.']);
    expect(host.paths, ['en.onnx', 'ru.onnx']);
  });

  test('pauses the current chunk and resumes the rest', () async {
    final release = Completer<void>();
    final client = _Client()..hold = release;
    final engine = PiperTtsEngine(
      voices: _installed(VoiceId.lessac),
      host: _Host(client),
    );
    addTearDown(engine.dispose);

    final pending = engine.speak('One. Two.', language: AppLanguage.en);
    await pumpEventQueue();
    expect(client.spoken, ['One.']);

    await engine.pause();
    expect((await pending).end, TtsUtteranceEnd.paused);
    expect(client.pauseCount, 1);
    expect(client.spoken, ['One.']);

    client.hold = null;
    release.complete();
    final resumed = await engine.resume();

    expect(resumed.end, TtsUtteranceEnd.completed);
    expect(client.resumeCount, 1);
    expect(client.spoken, ['One.', 'Two.']);
  });

  test('stop cancels the remaining chunks', () async {
    final client = _Client()..hold = Completer<void>();
    final engine = PiperTtsEngine(
      voices: _installed(VoiceId.irina),
      host: _Host(client),
    );
    addTearDown(engine.dispose);

    final pending = engine.speak('Раз. Два.', language: AppLanguage.ru);
    await pumpEventQueue();
    await engine.stop();

    expect((await pending).end, TtsUtteranceEnd.cancelled);
    expect(client.spoken, ['Раз.']);
    expect(client.stopCount, 1);
  });

  test('reports a missing quality voice', () async {
    final engine = PiperTtsEngine(
      voices: MemoryModelDownloader(),
      host: _Host(_Client()),
    );
    addTearDown(engine.dispose);

    expect(await engine.isAvailable(AppLanguage.ru), isFalse);
    final result = await engine.speak('Привет', language: AppLanguage.ru);

    expect(result.end, TtsUtteranceEnd.failed);
    expect(result.message, 'The Irina voice is not installed.');
  });

  test('uses system speech when the quality voice is missing', () async {
    final quality = FakeTtsEngine()..available[AppLanguage.ru] = false;
    final system = FakeTtsEngine();
    final engine = RoutingTtsEngine(quality: quality, system: system);
    addTearDown(engine.dispose);

    expect(await engine.isAvailable(AppLanguage.ru), isTrue);
    final russian = engine.speak('Привет', language: AppLanguage.ru);
    await pumpEventQueue();
    expect(system.spoken, ['Привет']);
    expect(quality.spoken, isEmpty);
    system.completeCurrent();
    await russian;

    final english = engine.speak('Hello', language: AppLanguage.en);
    await pumpEventQueue();
    expect(quality.spoken, ['Hello']);
    await engine.pause();
    expect(quality.pauseCount, 1);
    expect(system.pauseCount, 0);
    quality.completeCurrent();
    await english;
  });
}

MemoryModelDownloader _installed(VoiceId id) {
  return MemoryModelDownloader()
    ..models[id] = InstalledVoiceModel(
      modelPath: '${id.name}.onnx',
      configPath: '${id.name}.json',
    );
}

final class _Host implements PiperVoiceHost {
  _Host(this._client);

  final PiperVoiceClient _client;
  final paths = <String>[];

  @override
  Future<PiperVoiceClient> open({
    required String modelPath,
    required String configPath,
  }) async {
    paths.add(modelPath);
    return _client;
  }
}

final class _Client implements PiperVoiceClient {
  final spoken = <String>[];
  Completer<void>? hold;
  var pauseCount = 0;
  var resumeCount = 0;
  var stopCount = 0;

  @override
  Future<void> speak(String text) {
    spoken.add(text);
    final pending = hold;
    if (pending == null) return Future<void>.value();
    return pending.future;
  }

  @override
  Future<void> pause() async {
    pauseCount++;
  }

  @override
  Future<void> resume() async {
    resumeCount++;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {}
}
