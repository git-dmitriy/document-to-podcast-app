import 'package:document_to_podcast/app/app.dart';
import 'package:document_to_podcast/app/app_surface.dart';
import 'package:document_to_podcast/data/memory_settings_repository.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/data/tts_engine_factory.dart';
import 'package:document_to_podcast/domain/playback_settings.dart';
import 'package:document_to_podcast/domain/tts_engine.dart';
import 'package:document_to_podcast/ui/settings/settings_screen.dart';
import 'package:document_to_podcast/domain/voice_package.dart';
import 'package:document_to_podcast/ui/import/import_screen.dart';
import 'package:document_to_podcast/ui/library/delete_document.dart';
import 'package:document_to_podcast/ui/library/library_screen.dart';
import 'package:document_to_podcast/ui/library/system_speech_banner.dart';
import 'package:document_to_podcast/ui/settings/quality_voices_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_tts_engine.dart';
import 'support/memory_document_store.dart';
import 'support/memory_model_downloader.dart';

void main() {
  testWidgets('imports pasted Markdown and opens the reader', (tester) async {
    await _pumpLibrary(tester);

    expect(find.text('No documents yet'), findsOneWidget);

    await tester.tap(find.byKey(LibraryScreen.emptyImportKey));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Choose Markdown file')).dy,
      lessThan(tester.getTopLeft(find.byKey(ImportScreen.markdownFieldKey)).dy),
    );
    expect(find.text(SystemSpeechBanner.message), findsNothing);
    await tester.enterText(
      find.byKey(ImportScreen.markdownFieldKey),
      '# Hello\n\nBody text',
    );
    await tester.pump();
    await tester.tap(find.byKey(ImportScreen.saveButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    expect(find.text('Body text'), findsOneWidget);
    expect(find.text('Hello'), findsWidgets);
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(find.text('Speed'), findsOneWidget);
  });

  testWidgets('deletes a document after confirmation', (tester) async {
    final store = MemoryDocumentStore(newId: () => 'doc-1');
    await store.create(title: 'Hello', markdown: 'Body text');
    await _pumpLibrary(tester, store: store);

    await tester.tap(find.byTooltip('Delete Hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(confirmDeleteButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsNothing);
    expect(find.text('No documents yet'), findsOneWidget);
  });

  testWidgets('shows the reader beside the list on a wide window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = MemoryDocumentStore(newId: () => 'doc-1');
    await store.create(title: '', markdown: '# Hello\n\nBody text');
    await _pumpLibrary(tester, store: store);

    expect(find.text('Body text'), findsNothing);
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    expect(find.text('Body text'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byTooltip('Play'), findsOneWidget);
  });

  testWidgets('play and pause use the injected speech engine', (tester) async {
    final engine = FakeTtsEngine();
    final store = MemoryDocumentStore(newId: () => 'doc-1');
    await store.create(title: 'Hello', markdown: 'Body text');
    await _pumpLibrary(tester, store: store, speech: engine);

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();

    expect(engine.spoken, ['Body text']);
    expect(find.byTooltip('Pause'), findsOneWidget);

    engine.completeCurrent();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(engine.stopCount, 0);
  });

  testWidgets('saves speed and the default language from settings', (
    tester,
  ) async {
    final repository = MemorySettingsRepository();
    final store = MemoryDocumentStore(newId: () => 'doc-1');
    await store.create(title: 'Hello', markdown: 'Body text');
    await _pumpLibrary(tester, store: store, settingsRepository: repository);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    tester.widget<Slider>(find.byType(Slider)).onChangeEnd?.call(0.8);
    await tester.tap(find.text('Russian'));
    await tester.pumpAndSettle();

    expect(repository.settings.rate, 0.8);
    expect(repository.settings.fallbackLanguage, AppLanguage.ru);
    expect(find.text('Could not save settings.'), findsNothing);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    expect(tester.widget<Slider>(find.byType(Slider)).value, 0.8);
  });

  testWidgets('offers paste first and a system-speech banner on the web', (
    tester,
  ) async {
    await _pumpLibrary(tester, surface: AppSurface.web);

    expect(find.text(SystemSpeechBanner.message), findsOneWidget);
    expect(find.text(LibraryScreen.webEmptyBody), findsOneWidget);

    await tester.tap(find.byKey(LibraryScreen.emptyImportKey));
    await tester.pumpAndSettle();

    expect(find.text(ImportScreen.pasteHint), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(ImportScreen.markdownFieldKey)).dy,
      lessThan(tester.getTopLeft(find.text('Choose Markdown file')).dy),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(
      find.text('System speech is the only engine in the browser.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<RadioListTile<SpeechEngine>>(
            find.byKey(SettingsScreen.qualityEngineKey),
          )
          .enabled,
      isFalse,
    );
    await tester.scrollUntilVisible(
      find.text(QualityVoicesSection.webMessage),
      200,
    );
    expect(find.text(QualityVoicesSection.webMessage), findsOneWidget);
    expect(
      find.byKey(QualityVoicesSection.downloadKey(VoiceId.irina)),
      findsNothing,
    );
  });

  testWidgets('downloads a quality voice from settings', (tester) async {
    await _pumpLibrary(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(QualityVoicesSection.downloadKey(VoiceId.irina)),
      200,
    );
    await tester.tap(
      find.byKey(QualityVoicesSection.downloadKey(VoiceId.irina)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Installed'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(QualityVoicesSection.downloadKey(VoiceId.lessac)),
      200,
    );
    expect(
      find.byKey(QualityVoicesSection.downloadKey(VoiceId.lessac)),
      findsOneWidget,
    );
  });

  testWidgets('switches playback to the quality engine', (tester) async {
    final system = FakeTtsEngine();
    final quality = FakeTtsEngine();
    final repository = MemorySettingsRepository();
    final store = MemoryDocumentStore(newId: () => 'doc-1');
    await store.create(title: 'Hello', markdown: 'Body text');
    await _pumpLibrary(
      tester,
      store: store,
      settingsRepository: repository,
      engines: _MappedEngines({
        SpeechEngine.system: system,
        SpeechEngine.quality: quality,
      }),
    );

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();
    expect(system.spoken, ['Body text']);
    system.completeCurrent();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SettingsScreen.qualityEngineKey));
    await tester.pumpAndSettle();
    expect(repository.settings.engine, SpeechEngine.quality);
    expect(
      find.text("Quality speech uses the voice's natural pace."),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Play'));
    await tester.pump();

    expect(quality.spoken, ['Body text']);
    expect(system.spoken, ['Body text']);
    quality.completeCurrent();
    await tester.pumpAndSettle();
  });
}

Future<void> _pumpLibrary(
  WidgetTester tester, {
  MemoryDocumentStore? store,
  FakeTtsEngine? speech,
  MemorySettingsRepository? settingsRepository,
  MemoryModelDownloader? voices,
  TtsEngineFactory? engines,
  PlaybackSettings initialSettings = const PlaybackSettings(),
  AppSurface? surface,
}) async {
  await tester.pumpWidget(
    DocumentToPodcastApp(
      store: store ?? MemoryDocumentStore(),
      speech: speech,
      settingsRepository: settingsRepository ?? MemorySettingsRepository(),
      initialSettings: initialSettings,
      voices: voices ?? MemoryModelDownloader(),
      engines: engines,
      surface: surface,
    ),
  );
  await tester.pumpAndSettle();
}

final class _MappedEngines implements TtsEngineFactory {
  _MappedEngines(this._engines);

  final Map<SpeechEngine, TtsEngine> _engines;

  @override
  TtsEngine create(SpeechEngine engine) {
    final created = _engines[engine];
    if (created == null) {
      throw StateError('Missing ${engine.name} engine.');
    }
    return created;
  }
}
