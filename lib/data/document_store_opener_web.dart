import 'package:shared_preferences/shared_preferences.dart';

import 'document_store.dart';
import 'preferences_document_store.dart';

Future<DocumentStore> openDocumentStore() async {
  final preferences = await SharedPreferences.getInstance();
  return PreferencesDocumentStore(preferences);
}
