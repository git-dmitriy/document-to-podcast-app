import 'app_language.dart';

enum SpeechEngine { system }

final class PlaybackSettings {
  const PlaybackSettings({
    this.engine = SpeechEngine.system,
    this.rate = defaultRate,
    this.fallbackLanguage = AppLanguage.en,
  });

  static const minRate = 0.25;
  static const maxRate = 1.0;
  static const defaultRate = 0.5;

  final SpeechEngine engine;
  final double rate;
  final AppLanguage fallbackLanguage;

  PlaybackSettings copyWith({double? rate, AppLanguage? fallbackLanguage}) {
    return PlaybackSettings(
      rate: clampPlaybackRate(rate ?? this.rate),
      fallbackLanguage: fallbackLanguage ?? this.fallbackLanguage,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaybackSettings &&
        other.engine == engine &&
        other.rate == rate &&
        other.fallbackLanguage == fallbackLanguage;
  }

  @override
  int get hashCode => Object.hash(engine, rate, fallbackLanguage);
}

double clampPlaybackRate(double rate) {
  if (rate.isNaN) return PlaybackSettings.defaultRate;
  return rate
      .clamp(PlaybackSettings.minRate, PlaybackSettings.maxRate)
      .toDouble();
}
