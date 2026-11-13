import 'package:document_to_podcast/data/playback_wake_lock.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/document.dart';
import 'package:document_to_podcast/domain/tts_engine.dart';
import 'package:document_to_podcast/ui/reader/playback_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_tts_engine.dart';
import '../support/memory_playback_position_store.dart';

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

  test('uses the configured fallback when text has no letters', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(
      engine: engine,
      fallbackLanguage: AppLanguage.ru,
    );
    addTearDown(playback.dispose);

    final first = playback.play(document('123'));
    await pumpEventQueue();
    expect(engine.languages, [AppLanguage.ru]);
    engine.completeCurrent();
    await first;

    playback.setFallbackLanguage(AppLanguage.en);
    final second = playback.play(document('456'));
    await pumpEventQueue();
    expect(engine.languages, [AppLanguage.ru, AppLanguage.en]);
    engine.completeCurrent();
    await second;
    expect(playback.status, PlaybackStatus.idle);
  });

  test('switches engines and stops the current queue', () async {
    final first = FakeTtsEngine();
    final second = FakeTtsEngine();
    final playback = PlaybackController(engine: first);
    addTearDown(playback.dispose);

    final pending = playback.play(document('Hello.'));
    await pumpEventQueue();
    expect(first.spoken, ['Hello.']);

    await playback.useEngine(second);
    await pending;

    expect(playback.status, PlaybackStatus.idle);
    expect(first.stopCount, 1);

    final next = playback.play(document('Again.'));
    await pumpEventQueue();
    expect(second.spoken, ['Again.']);
    second.completeCurrent();
    await next;
    expect(playback.status, PlaybackStatus.idle);
  });

  test('exposes the current segment while speaking', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final pending = playback.play(document('First paragraph.\n\nSecond.'));
    await pumpEventQueue();

    expect(playback.currentSegment?.text, 'First paragraph.');
    expect(playback.segments, hasLength(2));

    engine.completeCurrent();
    await pumpEventQueue();
    expect(playback.currentSegment?.text, 'Second.');

    engine.completeCurrent();
    await pending;
    expect(playback.currentSegment, isNull);
  });

  test('moves to the next and previous paragraph', () async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final pending = playback.play(document('First paragraph.\n\nSecond.'));
    await pumpEventQueue();
    expect(playback.canSkipBackward, isFalse);
    expect(playback.canSkipForward, isTrue);

    final forward = playback.skipForward();
    await pumpEventQueue();
    expect(engine.spoken, ['First paragraph.', 'Second.']);
    expect(engine.stopCount, 1);
    expect(playback.segmentIndex, 1);

    final backward = playback.skipBackward();
    await pumpEventQueue();
    expect(engine.spoken, ['First paragraph.', 'Second.', 'First paragraph.']);
    expect(playback.canSkipBackward, isFalse);

    engine.completeCurrent();
    await pumpEventQueue();
    engine.completeCurrent();
    await forward;
    await backward;
    await pending;
  });

  test(
    'resumes a saved paragraph and restarts after the document ends',
    () async {
      final engine = FakeTtsEngine();
      final positions = MemoryPlaybackPositionStore();
      final playback = PlaybackController(engine: engine, positions: positions);
      addTearDown(playback.dispose);

      final first = playback.play(document('First paragraph.\n\nSecond.'));
      await pumpEventQueue();
      expect(positions.positions['doc-1'], 0);
      engine.completeCurrent();
      await pumpEventQueue();
      expect(positions.positions['doc-1'], 1);

      await playback.stop();
      await first;

      final resumed = playback.play(document('First paragraph.\n\nSecond.'));
      await pumpEventQueue();
      expect(engine.spoken.last, 'Second.');
      engine.completeCurrent();
      await resumed;
      expect(positions.positions['doc-1'], 0);

      final again = playback.play(document('First paragraph.\n\nSecond.'));
      await pumpEventQueue();
      expect(engine.spoken.last, 'First paragraph.');
      engine.completeCurrent();
      await pumpEventQueue();
      engine.completeCurrent();
      await again;
    },
  );

  test('keeps the screen awake only while speech is playing', () async {
    final engine = FakeTtsEngine();
    final wake = _WakeLock();
    final playback = PlaybackController(engine: engine, wakeLock: wake);
    addTearDown(playback.dispose);

    final pending = playback.play(document('Hello.'));
    await pumpEventQueue();
    expect(wake.enabled, isTrue);

    await playback.pause();
    await pumpEventQueue();
    expect(wake.enabled, isFalse);

    final resumed = playback.resume();
    await pumpEventQueue();
    expect(wake.enabled, isTrue);
    engine.completeCurrent();
    await resumed;
    await pending;
    await pumpEventQueue();
    expect(wake.enabled, isFalse);
  });

  test('forgets a saved position when the document is removed', () async {
    final engine = FakeTtsEngine();
    final positions = MemoryPlaybackPositionStore();
    final playback = PlaybackController(engine: engine, positions: positions);
    addTearDown(playback.dispose);

    final pending = playback.play(document('First paragraph.\n\nSecond.'));
    await pumpEventQueue();
    expect(positions.positions['doc-1'], 0);

    await playback.forget('doc-1');
    expect(positions.positions.containsKey('doc-1'), isFalse);

    engine.completeCurrent();
    await pumpEventQueue();
    expect(positions.positions.containsKey('doc-1'), isFalse);
    await playback.stop();
    await pending;
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

final class _WakeLock implements PlaybackWakeLock {
  var enabled = false;

  @override
  Future<void> enable() async {
    enabled = true;
  }

  @override
  Future<void> disable() async {
    enabled = false;
  }
}
