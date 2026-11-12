import 'dart:convert';
import 'dart:io';

import 'package:document_to_podcast/data/document_store_exception.dart';
import 'package:document_to_podcast/data/file_document_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('document_library_');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('persists a document and drops a missing body from the index', () async {
    var tick = 0;
    var ids = 0;
    FileDocumentStore store() {
      return FileDocumentStore(
        directory,
        clock: () => DateTime.utc(2026, 1, 1, 0, 0, tick++),
        newId: () => 'doc-${ids++}',
      );
    }

    final created = await store().create(
      title: '',
      markdown: '# Hello\r\n\r\nBody',
    );
    expect(created.title, 'Hello');
    expect(created.markdown, '# Hello\n\nBody');

    final reopened = await store().loadAll();
    expect(reopened, [created]);

    await File('${directory.path}/docs/doc-0.md').delete();
    expect(await store().loadAll(), isEmpty);
    expect(await store().loadAll(), isEmpty);
  });

  test('rejects empty markdown before writing files', () async {
    final store = FileDocumentStore(directory, newId: () => 'doc-1');

    expect(
      () => store.create(title: 'Note', markdown: ' \n\t'),
      throwsA(isA<DocumentStoreException>()),
    );
    expect(await directory.list().toList(), isEmpty);
  });

  test('rejects a corrupt or unsafe index', () async {
    await directory.create();
    final index = File('${directory.path}/index.json');
    await index.writeAsString('{');
    final store = FileDocumentStore(directory);

    expect(store.loadAll(), throwsA(isA<DocumentStoreException>()));

    await index.writeAsString(
      jsonEncode({
        'version': 1,
        'documents': [
          {
            'id': '../secrets',
            'title': 'Secret',
            'updatedAt': '2026-01-01T00:00:00.000Z',
          },
        ],
      }),
    );
    expect(store.loadAll(), throwsA(isA<DocumentStoreException>()));
  });
}
