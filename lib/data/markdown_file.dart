import 'dart:convert';

import 'document_store_exception.dart';

String decodeMarkdownFile({required String name, required List<int> bytes}) {
  final lower = name.toLowerCase();
  if (!lower.endsWith('.md') && !lower.endsWith('.markdown')) {
    throw const DocumentStoreException('Choose a Markdown file (.md).');
  }
  try {
    return utf8.decode(bytes);
  } on FormatException catch (error, stackTrace) {
    Error.throwWithStackTrace(
      DocumentStoreException('The file is not valid UTF-8.', cause: error),
      stackTrace,
    );
  }
}
