import 'package:flutter/material.dart';

import '../../data/document_store_exception.dart';
import '../../domain/document.dart';
import 'library_controller.dart';

const confirmDeleteButtonKey = Key('confirm-delete');

Future<bool> confirmDeleteDocument(
  BuildContext context,
  LibraryController controller,
  Document document,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete document?'),
        content: Text('"${document.title}" will be removed from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: confirmDeleteButtonKey,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await controller.delete(document.id);
    return true;
  } on DocumentStoreException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
  }
}
