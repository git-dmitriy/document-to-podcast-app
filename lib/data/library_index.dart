import 'dart:convert';

import '../domain/document.dart';
import 'document_id.dart';
import 'document_store_exception.dart';

const libraryIndexVersion = 1;

String encodeLibraryIndex(
  List<Document> documents, {
  required bool includeMarkdown,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'version': libraryIndexVersion,
    'documents': [
      for (final document in documents)
        {
          'id': document.id,
          'title': document.title,
          'updatedAt': document.updatedAt.toUtc().toIso8601String(),
          if (includeMarkdown) 'markdown': document.markdown,
        },
    ],
  });
}

List<IndexedDocument> decodeLibraryIndex(
  String source, {
  required bool requireMarkdown,
}) {
  try {
    return _decode(source, requireMarkdown: requireMarkdown);
  } on FormatException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      DocumentStoreException('The library index is unreadable.', cause: error),
      stackTrace,
    );
  }
}

List<IndexedDocument> _decode(String source, {required bool requireMarkdown}) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const FormatException('Expected an object.');
  }
  final version = decoded['version'];
  if (version is! int || version != libraryIndexVersion) {
    throw const FormatException('Unsupported library index.');
  }
  final entries = decoded['documents'];
  if (entries is! List) {
    throw const FormatException('Expected a document list.');
  }

  final documents = <IndexedDocument>[];
  final seen = <String>{};
  for (final entry in entries) {
    if (entry is! Map) {
      throw const FormatException('Expected a document object.');
    }
    final id = entry['id'];
    final title = entry['title'];
    final updatedAtRaw = entry['updatedAt'];
    if (id is! String ||
        !documentIdPattern.hasMatch(id) ||
        title is! String ||
        title.trim().isEmpty ||
        updatedAtRaw is! String) {
      throw const FormatException('Invalid document entry.');
    }
    if (!seen.add(id)) {
      throw const FormatException('Duplicate document id.');
    }
    final updatedAt = DateTime.tryParse(updatedAtRaw);
    if (updatedAt == null) {
      throw const FormatException('Invalid document timestamp.');
    }
    final markdown = entry['markdown'];
    if (markdown != null && markdown is! String) {
      throw const FormatException('Invalid document body.');
    }
    if (requireMarkdown && markdown is! String) {
      throw const FormatException('Missing document body.');
    }
    documents.add(
      IndexedDocument(
        id: id,
        title: title,
        updatedAt: updatedAt.toUtc(),
        markdown: markdown is String ? markdown : null,
      ),
    );
  }
  return documents;
}

final class IndexedDocument {
  const IndexedDocument({
    required this.id,
    required this.title,
    required this.updatedAt,
    this.markdown,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final String? markdown;
}
