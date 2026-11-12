import 'package:shared_preferences/shared_preferences.dart';

import '../domain/document.dart';
import 'async_lock.dart';
import 'document_id.dart';
import 'document_store.dart';
import 'document_store_exception.dart';
import 'library_index.dart';
import 'new_document.dart';

final class PreferencesDocumentStore implements DocumentStore {
  PreferencesDocumentStore(
    this._preferences, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _clock = clock ?? DateTime.now,
       _newId = newId ?? defaultDocumentId;

  static const indexKey = 'document_library_v1';

  final SharedPreferences _preferences;
  final DateTime Function() _clock;
  final String Function() _newId;
  final AsyncLock _lock = AsyncLock();

  @override
  Future<List<Document>> loadAll() {
    return _lock.run(() async => sortDocuments(await _readAll()));
  }

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
      final documents = await _readAll();
      if (documents.any((entry) => entry.id == document.id)) {
        throw const DocumentStoreException('Could not save the document.');
      }
      await _write(sortDocuments([...documents, document]));
      return document;
    });
  }

  @override
  Future<void> delete(String id) {
    return _lock.run(() async {
      if (!documentIdPattern.hasMatch(id)) {
        throw const DocumentStoreException('Could not delete the document.');
      }
      final documents = await _readAll();
      final remaining = [
        for (final document in documents)
          if (document.id != id) document,
      ];
      if (remaining.length != documents.length) {
        await _write(remaining);
      }
    });
  }

  Future<List<Document>> _readAll() async {
    final raw = _preferences.getString(indexKey);
    if (raw == null || raw.isEmpty) return const [];
    final entries = decodeLibraryIndex(raw, requireMarkdown: true);
    return [
      for (final entry in entries)
        Document(
          id: entry.id,
          title: entry.title,
          markdown: entry.markdown ?? '',
          updatedAt: entry.updatedAt,
        ),
    ];
  }

  Future<void> _write(List<Document> documents) async {
    final saved = await _preferences.setString(
      indexKey,
      encodeLibraryIndex(documents, includeMarkdown: true),
    );
    if (!saved) {
      throw const DocumentStoreException('Could not save the library.');
    }
  }
}
