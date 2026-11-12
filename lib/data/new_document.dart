import '../domain/document.dart';
import '../domain/document_title.dart';
import 'document_id.dart';
import 'document_store_exception.dart';

Document buildNewDocument({
  required String id,
  required DateTime updatedAt,
  required String title,
  required String markdown,
  String? sourceName,
}) {
  if (!documentIdPattern.hasMatch(id)) {
    throw const DocumentStoreException('Could not create a document id.');
  }
  final normalized = normalizeMarkdown(markdown);
  if (normalized.trim().isEmpty) {
    throw const DocumentStoreException('Markdown is empty.');
  }
  return Document(
    id: id,
    title: resolveDocumentTitle(
      markdown: normalized,
      requestedTitle: title,
      sourceName: sourceName,
    ),
    markdown: normalized,
    updatedAt: updatedAt.toUtc(),
  );
}
