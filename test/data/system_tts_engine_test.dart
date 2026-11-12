import 'package:document_to_podcast/data/system_tts_client.dart';
import 'package:document_to_podcast/data/system_tts_engine.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/tts_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('speaks after the platform reports completion', () async {
    final client = FakeSystemTtsClient();
    final engine = SystemTtsEngine(client: client);

    final result = engine.speak('Hello', language: AppLanguage.en);
    await pumpEventQueue();

    expect(client.prepared, isTrue);
    expect(client.languages, ['en-US']);
    expect(client.spoken, ['Hello']);
    client.complete();

    final spoken = await result;
    expect(spoken.end, TtsUtteranceEnd.completed);
  });

  test('pause and stop settle the utterance', () async {
    final client = FakeSystemTtsClient();
    final engine = SystemTtsEngine(client: client);

    final paused = engine.speak('Hello', language: AppLanguage.ru);
    await pumpEventQueue();
    expect(client.languages, ['ru-RU']);
    await engine.pause();
    expect((await paused).end, TtsUtteranceEnd.paused);

    final again = engine.resume();
    await pumpEventQueue();
    expect(client.spoken, ['Hello', 'Hello']);
    await engine.stop();
    expect((await again).end, TtsUtteranceEnd.cancelled);
    expect(client.stopCount, 1);
  });

  test('reads availability from bool, number, and string results', () async {
    final client = FakeSystemTtsClient();
    final engine = SystemTtsEngine(client: client);

    expect(await engine.isAvailable(AppLanguage.en), isTrue);

    client.availability = 0;
    expect(await engine.isAvailable(AppLanguage.en), isFalse);

    client.availability = '1';
    expect(await engine.isAvailable(AppLanguage.ru), isTrue);

    client.availability = 'false';
    expect(await engine.isAvailable(AppLanguage.ru), isFalse);
  });

  test('fails a section the platform refuses to start', () async {
    final client = FakeSystemTtsClient()..speakResult = 0;
    final engine = SystemTtsEngine(client: client);

    final result = await engine.speak('Hello', language: AppLanguage.en);

    expect(result.end, TtsUtteranceEnd.failed);
    expect(result.message, 'Could not speak this section.');
  });

  test('keeps a rate set before the engine is warmed', () async {
    final client = FakeSystemTtsClient();
    final engine = SystemTtsEngine(client: client);

    await engine.setRate(0.8);
    final pending = engine.speak('Hello', language: AppLanguage.en);
    await pumpEventQueue();

    expect(client.rates, contains(0.8));
    client.complete();
    await pending;
  });
}

final class FakeSystemTtsClient implements SystemTtsClient {
  Object? availability = true;
  Object? languageResult = 1;
  Object? speakResult = 1;
  final List<String> spoken = [];
  final List<String> languages = [];
  final List<double> rates = [];
  var prepared = false;
  var stopCount = 0;
  void Function()? onComplete;

  @override
  Future<void> prepare() async {
    prepared = true;
  }

  @override
  void bindUtterance({
    required void Function() onComplete,
    required void Function() onPause,
    required void Function() onCancel,
    required void Function(Object? message) onError,
  }) {
    this.onComplete = onComplete;
  }

  @override
  Future<Object?> isLanguageAvailable(String language) async => availability;

  @override
  Future<Object?> setLanguage(String language) async {
    languages.add(language);
    return languageResult;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    rates.add(rate);
  }

  @override
  Future<Object?> speak(String text) async {
    spoken.add(text);
    return speakResult;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {
    stopCount++;
  }

  void complete() => onComplete?.call();
}
