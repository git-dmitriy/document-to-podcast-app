import '../domain/playback_settings.dart';
import 'settings_repository.dart';

final class MemorySettingsRepository implements SettingsRepository {
  MemorySettingsRepository({
    PlaybackSettings initial = const PlaybackSettings(),
  }) : _settings = initial;

  PlaybackSettings _settings;

  PlaybackSettings get settings => _settings;

  @override
  Future<PlaybackSettings> load() async => _settings;

  @override
  Future<void> save(PlaybackSettings settings) async {
    _settings = settings;
  }
}
