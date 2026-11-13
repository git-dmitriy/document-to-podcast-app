import 'package:flutter/widgets.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/audio_cache_opener.dart';
import 'data/document_store_opener.dart';
import 'data/model_downloader_opener.dart';
import 'data/playback_position_opener.dart';
import 'data/playback_wake_lock_opener.dart';
import 'data/preferences_quality_prompt_store.dart';
import 'data/settings_repository_opener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await openDocumentStore();
  final settingsRepository = await openSettingsRepository();
  final settings = await settingsRepository.load();
  final voices = await openModelDownloader();
  final positions = await openPlaybackPositionStore();
  final wakeLock = await openPlaybackWakeLock();
  final audioCache = await openAudioCache();
  final preferences = await SharedPreferences.getInstance();
  final qualityPrompt = PreferencesQualityPromptStore(preferences);
  runApp(
    DocumentToPodcastApp(
      store: store,
      settingsRepository: settingsRepository,
      initialSettings: settings,
      voices: voices,
      qualityPrompt: qualityPrompt,
      positions: positions,
      wakeLock: wakeLock,
      audioCache: audioCache,
    ),
  );
}
