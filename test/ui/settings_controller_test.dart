import 'package:document_to_podcast/data/memory_settings_repository.dart';
import 'package:document_to_podcast/data/settings_exception.dart';
import 'package:document_to_podcast/data/settings_repository.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/playback_settings.dart';
import 'package:document_to_podcast/ui/settings/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('persists speed and the default language', () async {
    final repository = MemorySettingsRepository();
    final controller = SettingsController(
      repository: repository,
      initial: const PlaybackSettings(),
    );
    addTearDown(controller.dispose);

    await controller.setRate(0.1);
    await controller.setFallbackLanguage(AppLanguage.ru);

    expect(controller.settings.rate, PlaybackSettings.minRate);
    expect(controller.settings.fallbackLanguage, AppLanguage.ru);
    expect(repository.settings, controller.settings);
    expect(controller.errorMessage, isNull);
  });

  test('restores the previous settings when saving fails', () async {
    final controller = SettingsController(
      repository: _FailingSettingsRepository(),
      initial: const PlaybackSettings(),
    );
    addTearDown(controller.dispose);

    await controller.setRate(0.8);

    expect(controller.settings, const PlaybackSettings());
    expect(controller.errorMessage, 'Could not save settings.');
  });
}

final class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<PlaybackSettings> load() async => const PlaybackSettings();

  @override
  Future<void> save(PlaybackSettings settings) async {
    throw const SettingsException('Could not save settings.');
  }
}
