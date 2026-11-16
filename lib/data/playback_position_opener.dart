import 'package:shared_preferences/shared_preferences.dart';

import 'playback_position_store.dart';
import 'preferences_playback_position_store.dart';

Future<PlaybackPositionStore> openPlaybackPositionStore() async {
  final preferences = await SharedPreferences.getInstance();
  return PreferencesPlaybackPositionStore(preferences);
}
