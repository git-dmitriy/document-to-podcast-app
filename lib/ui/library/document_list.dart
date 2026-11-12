import 'package:flutter/material.dart';

import '../../domain/document.dart';

class DocumentList extends StatelessWidget {
  const DocumentList({
    required this.documents,
    required this.selectedId,
    required this.onOpen,
    required this.onDelete,
    super.key,
  });

  final List<Document> documents;
  final String? selectedId;
  final ValueChanged<Document> onOpen;
  final ValueChanged<Document> onDelete;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        final updated = localizations.formatShortDate(
          document.updatedAt.toLocal(),
        );
        return ListTile(
          key: ValueKey(document.id),
          selected: document.id == selectedId,
          title: Text(document.title),
          subtitle: Text(updated),
          onTap: () => onOpen(document),
          trailing: IconButton(
            tooltip: 'Delete ${document.title}',
            onPressed: () => onDelete(document),
            icon: const Icon(Icons.delete_outline),
          ),
        );
      },
    );
  }
}
