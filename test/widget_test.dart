import 'package:document_to_podcast/app/app.dart';
import 'package:document_to_podcast/ui/import/import_screen.dart';
import 'package:document_to_podcast/ui/library/delete_document.dart';
import 'package:document_to_podcast/ui/library/library_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/memory_document_store.dart';

void main() {
  testWidgets('imports pasted Markdown and opens the reader', (tester) async {
    await _pumpLibrary(tester);

    expect(find.text('No documents yet'), findsOneWidget);

    await tester.tap(find.byKey(LibraryScreen.emptyImportKey));
    await tester.pumpAndSettle();
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
  });
}

Future<void> _pumpLibrary(
  WidgetTester tester, {
  MemoryDocumentStore? store,
}) async {
  await tester.pumpWidget(
    DocumentToPodcastApp(store: store ?? MemoryDocumentStore()),
  );
  await tester.pumpAndSettle();
}
