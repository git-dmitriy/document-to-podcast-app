final class Document {
  const Document({
    required this.id,
    required this.title,
    required this.markdown,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String markdown;
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) {
    return other is Document &&
        other.id == id &&
        other.title == title &&
        other.markdown == markdown &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(id, title, markdown, updatedAt);
}

List<Document> sortDocuments(Iterable<Document> documents) {
  final sorted = [...documents]
    ..sort((a, b) {
      final byDate = b.updatedAt.compareTo(a.updatedAt);
      if (byDate != 0) return byDate;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
  return List.unmodifiable(sorted);
}
