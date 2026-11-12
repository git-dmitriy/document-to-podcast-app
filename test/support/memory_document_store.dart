import 'package:document_to_podcast/data/async_lock.dart';
import 'package:document_to_podcast/data/document_id.dart';
import 'package:document_to_podcast/data/document_store.dart';
import 'package:document_to_podcast/data/new_document.dart';
import 'package:document_to_podcast/domain/document.dart';

final class MemoryDocumentStore implements DocumentStore {
  MemoryDocumentStore({DateTime Function()? clock, String Function()? newId})
    : _clock = clock ?? DateTime.now,
      _newId = newId ?? defaultDocumentId;

  final DateTime Function() _clock;
  final String Function() _newId;
  final List<Document> _documents = [];
  final AsyncLock _lock = AsyncLock();

  @override
  Future<Document> create({
    required String title,
    required String markdown,
    String? sourceName,
  }) {
    final document = buildNewDocument(
      id: _newId(),
      updatedAt: _clock(),
      title: title,
      markdown: markdown,
      sourceName: sourceName,
    );
    return _lock.run(() async {
      _documents.add(document);
      return document;
    });
  }

  @override
  Future<void> delete(String id) {
    return _lock.run(() async {
      _documents.removeWhere((document) => document.id == id);
    });
  }

  @override
  Future<List<Document>> loadAll() {
    return _lock.run(() async => sortDocuments(_documents));
  }
}
