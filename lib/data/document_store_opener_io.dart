import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'document_store.dart';
import 'file_document_store.dart';

Future<DocumentStore> openDocumentStore() async {
  final root = await getApplicationDocumentsDirectory();
  final text = root.uri.toString();
  final base = text.endsWith('/') ? root.uri : Uri.parse('$text/');
  return FileDocumentStore(Directory.fromUri(base.resolve('library/')));
}
