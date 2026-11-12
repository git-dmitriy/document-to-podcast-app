import 'package:flutter/widgets.dart';

import 'app/app.dart';
import 'data/document_store_opener.dart';
import 'data/settings_repository_opener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openDocumentStore();
  final settingsRepository = await openSettingsRepository();
  final settings = await settingsRepository.load();
  runApp(
    DocumentToPodcastApp(
      store: store,
      settingsRepository: settingsRepository,
      initialSettings: settings,
    ),
  );
}
