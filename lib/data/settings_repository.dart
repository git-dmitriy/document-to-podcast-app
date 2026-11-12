import '../domain/playback_settings.dart';

abstract interface class SettingsRepository {
  Future<PlaybackSettings> load();

  Future<void> save(PlaybackSettings settings);
}
