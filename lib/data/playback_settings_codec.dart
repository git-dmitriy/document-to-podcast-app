import 'dart:convert';

import '../domain/app_language.dart';
import '../domain/playback_settings.dart';

const playbackSettingsKey = 'playback_settings_v1';
const playbackSettingsVersion = 1;

String encodePlaybackSettings(PlaybackSettings settings) {
  return jsonEncode({
    'version': playbackSettingsVersion,
    'engine': SpeechEngine.system.name,
    'rate': settings.rate,
    'language': settings.fallbackLanguage.name,
  });
}

/// Unreadable settings fall back to the system-speech defaults.
PlaybackSettings decodePlaybackSettings(String? source) {
  if (source == null || source.trim().isEmpty) {
    return const PlaybackSettings();
  }
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map) return const PlaybackSettings();
    final version = decoded['version'];
    if (version != playbackSettingsVersion) return const PlaybackSettings();
    final languageRaw = decoded['language'];
    final language = languageRaw is String
        ? AppLanguage.byCode(languageRaw)
        : null;
    return PlaybackSettings(
      rate: _rate(decoded['rate']),
      fallbackLanguage: language ?? AppLanguage.en,
    );
  } on FormatException {
    return const PlaybackSettings();
  }
}

double _rate(Object? value) {
  if (value is! num || value.isNaN) return PlaybackSettings.defaultRate;
  return clampPlaybackRate(value.toDouble());
}
