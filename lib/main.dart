import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'data/document_store_opener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openDocumentStore();
  runApp(DocumentToPodcastApp(store: store));
}
