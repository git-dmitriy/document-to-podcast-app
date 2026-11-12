import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/playback_settings.dart';
import 'playback_settings_codec.dart';
import 'settings_exception.dart';
import 'settings_repository.dart';

final class PreferencesSettingsRepository implements SettingsRepository {
  PreferencesSettingsRepository(this._preferences);

  final SharedPreferences _preferences;

  @override
  Future<PlaybackSettings> load() async {
    return decodePlaybackSettings(_preferences.getString(playbackSettingsKey));
  }

  @override
  Future<void> save(PlaybackSettings settings) async {
    try {
      final saved = await _preferences.setString(
        playbackSettingsKey,
        encodePlaybackSettings(settings),
      );
      if (!saved) {
        throw const SettingsException('Could not save settings.');
      }
    } on SettingsException {
      rethrow;
    } on PlatformException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SettingsException('Could not save settings.', cause: error),
        stackTrace,
      );
    }
  }
}
