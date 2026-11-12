import 'package:document_to_podcast/data/document_store.dart';
import 'package:document_to_podcast/data/document_store_exception.dart';
import 'package:document_to_podcast/domain/document.dart';
import 'package:document_to_podcast/ui/library/library_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_document_store.dart';

void main() {
  test('import adds a document and delete clears the selection', () async {
    final controller = LibraryController(store: MemoryDocumentStore());
    addTearDown(controller.dispose);

    final document = await controller.importMarkdown(
      title: '',
      markdown: '# Hello\n\nBody',
    );
    controller.select(document.id);
    expect(controller.state.documents.single.title, 'Hello');
    expect(controller.state.selectedId, document.id);

    await controller.delete(document.id);
    expect(controller.state.documents, isEmpty);
    expect(controller.state.selectedId, isNull);
  });

  test('keeps the library closed when markdown is empty', () async {
    final controller = LibraryController(store: MemoryDocumentStore());
    addTearDown(controller.dispose);

    await expectLater(
      controller.importMarkdown(title: 'Note', markdown: ' '),
      throwsA(isA<DocumentStoreException>()),
    );
    expect(controller.state.documents, isEmpty);
  });

  test(
    'shows a load error without dropping documents already on screen',
    () async {
      final controller = LibraryController(store: _BrokenStore());
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.errorMessage, 'Could not read the library.');
      expect(controller.state.documents, isEmpty);
    },
  );
}

final class _BrokenStore implements DocumentStore {
  @override
  Future<List<Document>> loadAll() async {
    throw const DocumentStoreException('Could not read the library.');
  }

  @override
  Future<Document> create({
    required String title,
    required String markdown,
    String? sourceName,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> delete(String id) {
    throw UnimplementedError();
  }
}
