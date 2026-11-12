import 'package:document_to_podcast/app/app.dart';
import 'package:document_to_podcast/app/app_surface.dart';
import 'package:document_to_podcast/data/memory_settings_repository.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/playback_settings.dart';
import 'package:document_to_podcast/ui/import/import_screen.dart';
import 'package:document_to_podcast/ui/library/delete_document.dart';
import 'package:document_to_podcast/ui/library/library_screen.dart';
import 'package:document_to_podcast/ui/library/system_speech_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_tts_engine.dart';
import 'support/memory_document_store.dart';

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
  });
}

Future<void> _pumpLibrary(
  WidgetTester tester, {
  MemoryDocumentStore? store,
  FakeTtsEngine? speech,
  MemorySettingsRepository? settingsRepository,
  PlaybackSettings initialSettings = const PlaybackSettings(),
  AppSurface? surface,
}) async {
  await tester.pumpWidget(
    DocumentToPodcastApp(
      store: store ?? MemoryDocumentStore(),
      speech: speech,
      settingsRepository: settingsRepository ?? MemorySettingsRepository(),
      initialSettings: initialSettings,
      surface: surface,
    ),
  );
  await tester.pumpAndSettle();
}
