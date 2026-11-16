import 'package:document_to_podcast/domain/document.dart';
import 'package:document_to_podcast/domain/tts_engine.dart';
import 'package:document_to_podcast/ui/reader/playback_controller.dart';
import 'package:document_to_podcast/ui/reader/segment_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_tts_engine.dart';

void main() {
  test('spokenHighlightRect locates the spoken characters', () {
    const text = 'Hello spoken world';
    final rect = spokenHighlightRect(
      text: text,
      highlight: const TtsUtteranceProgress(start: 6, end: 12),
      style: const TextStyle(fontSize: 16, height: 1.45),
      maxWidth: 320,
      textDirection: TextDirection.ltr,
    );

    expect(rect, isNotNull);
    expect(rect!.left, greaterThan(0));
    expect(rect.width, greaterThan(0));
    expect(rect.height, greaterThan(0));
  });

  test('spokenHighlightRect returns null for an empty range', () {
    final rect = spokenHighlightRect(
      text: 'Hello',
      highlight: const TtsUtteranceProgress(start: 2, end: 2),
      style: const TextStyle(fontSize: 16),
      maxWidth: 200,
      textDirection: TextDirection.ltr,
    );

    expect(rect, isNull);
  });

  testWidgets('keeps a later spoken passage in view', (tester) async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final markdown = [
      for (var index = 0; index < 24; index++)
        'Passage $index with enough words to take vertical space in the reader.',
    ].join('\n\n');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: playback,
            builder: (context, _) {
              if (playback.status == PlaybackStatus.idle ||
                  playback.segments.isEmpty) {
                return const SizedBox.expand();
              }
              return SegmentReader(
                playback: playback,
                segments: playback.segments,
              );
            },
          ),
        ),
      ),
    );

    final pending = playback.play(
      Document(
        id: 'doc-1',
        title: 'Note',
        markdown: markdown,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await tester.pump();
    await tester.pump();

    for (var index = 0; index < 12; index++) {
      engine.completeCurrent();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 320));
    }

    expect(playback.segmentIndex, 12);
    final spoken = find.textContaining('Passage 12', findRichText: true);
    expect(spoken, findsWidgets);

    final rect = tester.getRect(spoken.first);
    final view = tester.getRect(find.byType(Scrollable).first);
    expect(rect.top, greaterThanOrEqualTo(view.top - 8));
    expect(rect.top, lessThan(view.bottom));

    await playback.stop();
    await pending;
  });

  testWidgets('follows highlight updates inside the active passage', (
    tester,
  ) async {
    final engine = FakeTtsEngine();
    final playback = PlaybackController(engine: engine);
    addTearDown(playback.dispose);

    final body = [
      'Alpha words stay first.',
      for (var index = 0; index < 40; index++)
        'Line $index keeps the passage tall enough to require scrolling.',
      'Charlie words mark the spoken range near the end of this passage.',
    ].join(' ');

    tester.view.physicalSize = const Size(400, 240);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: playback,
            builder: (context, _) {
              if (playback.status == PlaybackStatus.idle ||
                  playback.segments.isEmpty) {
                return const SizedBox.expand();
              }
              return SegmentReader(
                playback: playback,
                segments: playback.segments,
              );
            },
          ),
        ),
      ),
    );

    final pending = playback.play(
      Document(
        id: 'doc-1',
        title: 'Note',
        markdown: body,
        updatedAt: DateTime.utc(2026, 1, 1),
      ),
    );
    await tester.pump();
    await tester.pump();

    final startOffset = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;

    final text = playback.currentSegment!.text;
    final start = text.indexOf('Charlie');
    expect(start, greaterThan(0));
    engine.emitProgress(
      TtsUtteranceProgress(start: start, end: start + 'Charlie'.length),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final endOffset = tester
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(endOffset, greaterThan(startOffset));

    await playback.stop();
    await pending;
  });
}
