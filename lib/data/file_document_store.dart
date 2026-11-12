import 'dart:io';

import '../domain/document.dart';
import 'async_lock.dart';
import 'document_id.dart';
import 'document_store.dart';
import 'document_store_exception.dart';
import 'library_index.dart';
import 'new_document.dart';

final class FileDocumentStore implements DocumentStore {
  FileDocumentStore(
    Directory root, {
    DateTime Function()? clock,
    String Function()? newId,
  }) : _root = root,
       _clock = clock ?? DateTime.now,
       _newId = newId ?? defaultDocumentId;

  final Directory _root;
  final DateTime Function() _clock;
  final String Function() _newId;
  final AsyncLock _lock = AsyncLock();

  Uri get _base {
    final text = _root.uri.toString();
    if (text.endsWith('/')) return _root.uri;
    return Uri.parse('$text/');
  }

  File get _indexFile => File.fromUri(_base.resolve('index.json'));

  File _documentFile(String id) => File.fromUri(_base.resolve('docs/$id.md'));

  @override
  Future<List<Document>> loadAll() {
    return _lock.run(_readAll);
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
      final file = _documentFile(document.id);
      try {
        final entries = await _readEntries();
        if (entries.any((entry) => entry.id == document.id)) {
          throw const DocumentStoreException('Could not save the document.');
        }
        await Directory.fromUri(_base.resolve('docs/')).create(recursive: true);
        await file.writeAsString(document.markdown, flush: true);
        await _writeEntries([
          ...entries,
          IndexedDocument(
            id: document.id,
            title: document.title,
            updatedAt: document.updatedAt,
          ),
        ]);
        return document;
      } on DocumentStoreException {
        rethrow;
      } on IOException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          DocumentStoreException('Could not save the document.', cause: error),
          stackTrace,
        );
      }
    });
  }

  @override
  Future<void> delete(String id) {
    return _lock.run(() async {
      if (!documentIdPattern.hasMatch(id)) {
        throw const DocumentStoreException('Could not delete the document.');
      }
      try {
        final entries = await _readEntries();
        final file = _documentFile(id);
        if (await file.exists()) {
          await file.delete();
        }
        final remaining = [
          for (final entry in entries)
            if (entry.id != id) entry,
        ];
        if (remaining.length != entries.length) {
          await _writeEntries(remaining);
        }
      } on DocumentStoreException {
        rethrow;
      } on IOException catch (error, stackTrace) {
        Error.throwWithStackTrace(
          DocumentStoreException(
            'Could not delete the document.',
            cause: error,
          ),
          stackTrace,
        );
      }
    });
  }

  Future<List<Document>> _readAll() async {
    final entries = await _readEntries();
    final documents = <Document>[];
    for (final entry in entries) {
      final file = _documentFile(entry.id);
      if (!await file.exists()) continue;
      documents.add(
        Document(
          id: entry.id,
          title: entry.title,
          markdown: await file.readAsString(),
          updatedAt: entry.updatedAt,
        ),
      );
    }
    final sorted = sortDocuments(documents);
    if (documents.length != entries.length) {
      await _writeIndex(sorted);
    }
    return sorted;
  }

  Future<List<IndexedDocument>> _readEntries() async {
    final index = _indexFile;
    if (!await index.exists()) return const [];
    return decodeLibraryIndex(
      await index.readAsString(),
      requireMarkdown: false,
    );
  }

  Future<void> _writeEntries(List<IndexedDocument> entries) {
    return _writeIndex([
      for (final entry in entries)
        Document(
          id: entry.id,
          title: entry.title,
          markdown: '',
          updatedAt: entry.updatedAt,
        ),
    ]);
  }

  Future<void> _writeIndex(List<Document> documents) async {
    final encoded = encodeLibraryIndex(
      sortDocuments(documents),
      includeMarkdown: false,
    );
    final index = _indexFile;
    final temp = File.fromUri(_base.resolve('index.json.tmp'));
    await temp.writeAsString(encoded, flush: true);
    await temp.rename(index.path);
  }
}
