import '../domain/document.dart';

abstract interface class DocumentStore {
  Future<List<Document>> loadAll();

  Future<Document> create({
    required String title,
    required String markdown,
    String? sourceName,
  });

  Future<void> delete(String id);
}
