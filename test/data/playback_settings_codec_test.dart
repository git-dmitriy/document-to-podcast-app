import 'package:document_to_podcast/data/playback_settings_codec.dart';
import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/playback_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns defaults for missing or unreadable settings', () {
    expect(decodePlaybackSettings(null), const PlaybackSettings());
    expect(decodePlaybackSettings(' '), const PlaybackSettings());
    expect(decodePlaybackSettings('{'), const PlaybackSettings());
    expect(
      decodePlaybackSettings('{"version":2,"rate":0.8,"language":"ru"}'),
      const PlaybackSettings(),
    );
  });

  test('keeps a usable rate and language from a partial record', () {
    final settings = decodePlaybackSettings(
      '{"version":1,"engine":"quality","rate":2,"language":"ru"}',
    );

    expect(settings.engine, SpeechEngine.system);
    expect(settings.rate, PlaybackSettings.maxRate);
    expect(settings.fallbackLanguage, AppLanguage.ru);
  });

  test('round-trips the stored settings', () {
    const settings = PlaybackSettings(
      rate: 0.8,
      fallbackLanguage: AppLanguage.ru,
    );

    expect(decodePlaybackSettings(encodePlaybackSettings(settings)), settings);
  });
}
