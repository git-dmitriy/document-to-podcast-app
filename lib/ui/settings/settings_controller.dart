import 'package:flutter/foundation.dart';

import '../../data/async_lock.dart';
import '../../data/settings_exception.dart';
import '../../data/settings_repository.dart';
import '../../domain/app_language.dart';
import '../../domain/playback_settings.dart';

final class SettingsController extends ChangeNotifier {
  SettingsController({
    required this._repository,
    required PlaybackSettings initial,
  }) : _settings = initial;

  final SettingsRepository _repository;
  final AsyncLock _lock = AsyncLock();
  PlaybackSettings _settings;
  String? _error;
  var _disposed = false;

  PlaybackSettings get settings => _settings;

  String? get errorMessage => _error;

  Future<void> setRate(double rate) {
    return _lock.run(() {
      final next = clampPlaybackRate(rate);
      if (next == _settings.rate) return Future<void>.value();
      return _save(_settings.copyWith(rate: next));
    });
  }

  Future<void> setFallbackLanguage(AppLanguage language) {
    return _lock.run(() {
      if (language == _settings.fallbackLanguage) return Future<void>.value();
      return _save(_settings.copyWith(fallbackLanguage: language));
    });
  }

  Future<void> _save(PlaybackSettings next) async {
    final previous = _settings;
    _settings = next;
    _error = null;
    _notify();
    try {
      await _repository.save(next);
    } on SettingsException catch (error) {
      if (_disposed) return;
      _settings = previous;
      _error = error.message;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
