import 'package:document_to_podcast/data/playback_settings_codec.dart';
import 'package:document_to_podcast/data/preferences_settings_repository.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/playback_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loads defaults when nothing is stored', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesSettingsRepository(preferences);

    expect(await repository.load(), const PlaybackSettings());
  });

  test('saves and reloads playback settings', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesSettingsRepository(preferences);
    const settings = PlaybackSettings(
      rate: 0.8,
      fallbackLanguage: AppLanguage.ru,
    );

    await repository.save(settings);
    final again = PreferencesSettingsRepository(preferences);

    expect(await again.load(), settings);
    expect(preferences.getString(playbackSettingsKey), isNotNull);
  });

  test('falls back when the stored record is corrupt', () async {
    SharedPreferences.setMockInitialValues({playbackSettingsKey: '{'});
    final preferences = await SharedPreferences.getInstance();
    final repository = PreferencesSettingsRepository(preferences);

    expect(await repository.load(), const PlaybackSettings());
  });
}
