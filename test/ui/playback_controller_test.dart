import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/document.dart';
import 'package:document_to_podcast/domain/tts_engine.dart';
import 'package:document_to_podcast/ui/reader/playback_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_tts_engine.dart';

void main() {
  Document document(String markdown) {
    return Document(
      id: 'doc-1',
      title: 'Note',
      markdown: markdown,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }

  test('speaks text segments and skips code blocks', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final pending = playback.play(
      document('# Title\n\n```\nsecret\n```\n\nAfter.'),
    );
    await pumpEventQueue();
    expect(engine.spoken, ['Title']);
    expect(playback.status, PlaybackStatus.playing);

    engine.completeCurrent();
    await pumpEventQueue();
    expect(engine.spoken, ['Title', 'After.']);

    engine.completeCurrent();
    await pending;
    expect(playback.status, PlaybackStatus.idle);
    expect(playback.errorMessage, isNull);
    expect(playback.documentId, isNull);
    expect(engine.spoken, isNot(contains('secret')));
  });

  test('pause holds the current segment and resume continues it', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final pending = playback.play(document('First paragraph.\n\nSecond.'));
    await pumpEventQueue();
    expect(engine.spoken, ['First paragraph.']);

    await playback.pause();
    expect(playback.status, PlaybackStatus.paused);
    expect(engine.pauseCount, 1);
    expect(engine.spoken, ['First paragraph.']);

    final resumed = playback.resume();
    await pumpEventQueue();
    expect(playback.status, PlaybackStatus.playing);
    expect(engine.resumed, ['First paragraph.']);

    engine.completeCurrent();
    await pumpEventQueue();
    expect(engine.spoken, ['First paragraph.', 'Second.']);

    engine.completeCurrent();
    await resumed;
    await pending;
    expect(playback.status, PlaybackStatus.idle);
  });

  test('pause before the next segment resumes at that segment', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);
    engine.onRate = (count) async {
      if (count == 2) await playback.pause();
    };

    final pending = playback.play(document('First paragraph.\n\nSecond.'));
    await pumpEventQueue();
    engine.completeCurrent();
    await pumpEventQueue();

    expect(playback.status, PlaybackStatus.paused);
    expect(engine.spoken, ['First paragraph.']);

    final resumed = playback.resume();
    await pumpEventQueue();
    expect(engine.spoken, ['First paragraph.', 'Second.']);
    expect(engine.resumed, isEmpty);

    engine.completeCurrent();
    await resumed;
    await pending;
    expect(playback.status, PlaybackStatus.idle);
  });

  test('stop drops the rest of the queue', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final pending = playback.play(document('First paragraph.\n\nSecond.'));
    await pumpEventQueue();
    expect(engine.spoken, ['First paragraph.']);

    await playback.stop();
    engine.completeCurrent();
    await pending;

    expect(playback.status, PlaybackStatus.idle);
    expect(engine.spoken, ['First paragraph.']);
    expect(engine.stopCount, 1);
  });

  test('a new play replaces the previous queue', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final first = playback.play(document('Alpha paragraph.\n\nLater.'));
    await pumpEventQueue();
    expect(engine.spoken, ['Alpha paragraph.']);

    final second = playback.play(
      document('Beta paragraph.').copyWithId('doc-2'),
    );
    await pumpEventQueue();

    expect(engine.spoken, ['Alpha paragraph.', 'Beta paragraph.']);
    engine.completeCurrent();
    await second;
    await first;
    expect(engine.spoken, ['Alpha paragraph.', 'Beta paragraph.']);
    expect(playback.status, PlaybackStatus.idle);
  });

  test('skips a language the device cannot speak', () async {
    final engine = FakeTtsEngine()..available[AppLanguage.ru] = false;
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final pending = playback.play(document('# Заголовок\n\nHello'));
    await pumpEventQueue();
    expect(engine.spoken, ['Hello']);

    engine.completeCurrent();
    await pending;
    expect(playback.status, PlaybackStatus.idle);
    expect(
      playback.errorMessage,
      'Speech for ru-RU is not available on this device.',
    );
  });

  test('reports an empty document without speaking', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    await playback.play(document('```\nsecret\n```'));

    expect(engine.spoken, isEmpty);
    expect(playback.status, PlaybackStatus.idle);
    expect(playback.errorMessage, 'Nothing to read in this document.');
  });

  test('applies the selected rate before speaking', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    await playback.setRate(0.1);
    expect(playback.rate, PlaybackController.minRate);
    expect(engine.rates, isEmpty);

    final pending = playback.play(document('Hello.'));
    await pumpEventQueue();
    expect(engine.rates, [PlaybackController.minRate]);

    engine.completeCurrent();
    await pending;
  });

  test('surfaces an engine failure and stays idle', () async {
    final engine = FakeTtsEngine()
      ..availabilityFailure = const TtsFailure(
        'System speech is not available on this device.',
      );
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    await playback.play(document('Hello.'));

    expect(engine.spoken, isEmpty);
    expect(playback.status, PlaybackStatus.idle);
    expect(
      playback.errorMessage,
      'System speech is not available on this device.',
    );
  });
}

extension on Document {
  Document copyWithId(String id) {
    return Document(
      id: id,
      title: title,
      markdown: markdown,
      updatedAt: updatedAt,
    );
  }
}
