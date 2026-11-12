import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/app_language.dart';
import '../../domain/document.dart';
import '../../domain/language_detector.dart';
import '../../domain/markdown_speech_compiler.dart';
import '../../domain/playback_settings.dart';
import '../../domain/speech_segment.dart';
import '../../domain/tts_engine.dart';

enum PlaybackStatus { idle, playing, paused }

/// Plays a document as a queue of speech segments.
final class PlaybackController extends ChangeNotifier {
  PlaybackController({
    required this._engine,
    MarkdownSpeechCompiler? compiler,
    AppLanguage fallbackLanguage = AppLanguage.en,
    double? rate,
  }) : _fallback = fallbackLanguage,
       _rate = clampPlaybackRate(rate ?? PlaybackSettings.defaultRate),
       _compiler =
           compiler ??
           MarkdownSpeechCompiler(
             languages: LanguageDetector(fallback: fallbackLanguage),
           );

  static const minRate = PlaybackSettings.minRate;
  static const maxRate = PlaybackSettings.maxRate;
  static const defaultRate = PlaybackSettings.defaultRate;

  final TtsEngine _engine;
  AppLanguage _fallback;
  MarkdownSpeechCompiler _compiler;
  final Map<AppLanguage, bool> _availability = {};
  final Set<AppLanguage> _unavailable = {};

  PlaybackStatus _status = PlaybackStatus.idle;
  String? _documentId;
  String? _error;
  double _rate;
  List<SpeechSegment> _segments = const [];
  var _index = 0;
  var _generation = 0;
  var _held = false;
  var _disposed = false;

  PlaybackStatus get status => _status;

  String? get documentId => _documentId;

  String? get errorMessage => _error;

  double get rate => _rate;

  Future<void> play(Document document) async {
    await stop();
    if (_disposed) return;
    final generation = ++_generation;
    final segments = [
      for (final segment in _compiler.compile(document.markdown).segments)
        if (segment.kind != SpeechSegmentKind.skip && segment.text.isNotEmpty)
          segment,
    ];
    if (!_isCurrent(generation)) return;
    _availability.clear();
    _unavailable.clear();
    if (segments.isEmpty) {
      _error = 'Nothing to read in this document.';
      _notify();
      return;
    }
    _segments = List.unmodifiable(segments);
    _index = 0;
    _documentId = document.id;
    _held = false;
    _status = PlaybackStatus.playing;
    _error = null;
    _notify();
    await _drain(generation);
  }

  Future<void> pause() async {
    if (_disposed || _status != PlaybackStatus.playing) return;
    _status = PlaybackStatus.paused;
    _notify();
    try {
      await _engine.pause();
    } on TtsFailure catch (error) {
      _error = error.message;
      _status = PlaybackStatus.idle;
      _held = false;
      _notify();
      return;
    }
    // The queue records a held utterance when the speak future completes.
    await Future<void>.value();
  }

  Future<void> resume() async {
    if (_disposed || _status != PlaybackStatus.paused) return;
    final generation = _generation;
    final held = _held;
    _held = false;
    _status = PlaybackStatus.playing;
    _notify();
    await _drain(generation, resumeCurrent: held);
  }

  Future<void> stop() async {
    if (_disposed) return;
    final generation = ++_generation;
    final active = _status != PlaybackStatus.idle || _held;
    _status = PlaybackStatus.idle;
    _held = false;
    _index = 0;
    _segments = const [];
    _documentId = null;
    _error = null;
    _notify();
    if (!active) return;
    try {
      await _engine.stop();
    } on TtsFailure catch (error) {
      if (_isCurrent(generation)) {
        _error = error.message;
        _notify();
      }
    } catch (error, stackTrace) {
      _report(error, stackTrace);
      if (_isCurrent(generation)) {
        _error = 'Playback failed.';
        _notify();
      }
    }
  }

  void setFallbackLanguage(AppLanguage language) {
    if (_disposed || _fallback == language) return;
    _fallback = language;
    _compiler = MarkdownSpeechCompiler(
      languages: LanguageDetector(fallback: language),
    );
  }

  Future<void> setRate(double rate) async {
    if (_disposed || rate.isNaN) return;
    final next = clampPlaybackRate(rate);
    if (next == _rate) return;
    _rate = next;
    _notify();
    if (_status == PlaybackStatus.idle) return;
    try {
      await _engine.setRate(_rate);
    } on TtsFailure catch (error) {
      _error = error.message;
      _notify();
    }
  }

  @override
  void dispose() {
    final active = _status != PlaybackStatus.idle || _held;
    _disposed = true;
    _generation++;
    _status = PlaybackStatus.idle;
    if (active) unawaited(_halt());
    super.dispose();
  }

  Future<void> _drain(int generation, {bool resumeCurrent = false}) async {
    var resume = resumeCurrent;
    while (_isCurrent(generation) && _index < _segments.length) {
      if (_status != PlaybackStatus.playing) return;
      final segment = _segments[_index];
      final available = await _languageAvailable(generation, segment.language);
      if (available == null || !_isCurrent(generation)) return;
      if (_status != PlaybackStatus.playing) return;
      if (!available) {
        _noteUnavailable(segment.language);
        _index++;
        resume = false;
        continue;
      }
      try {
        await _engine.setRate(_rate);
      } on TtsFailure catch (error) {
        _fail(generation, error.message);
        return;
      }
      if (!_isCurrent(generation) || _status != PlaybackStatus.playing) return;
      final TtsSpeakResult result;
      try {
        result = resume
            ? await _engine.resume()
            : await _engine.speak(segment.text, language: segment.language);
      } on TtsFailure catch (error) {
        _fail(generation, error.message);
        return;
      }
      resume = false;
      if (!_isCurrent(generation)) return;
      switch (result.end) {
        case TtsUtteranceEnd.completed:
          _index++;
        case TtsUtteranceEnd.paused:
          _held = true;
          _status = PlaybackStatus.paused;
          _notify();
          return;
        case TtsUtteranceEnd.cancelled:
          if (_status != PlaybackStatus.paused) {
            _status = PlaybackStatus.idle;
            _held = false;
            _index = 0;
            _segments = const [];
            _documentId = null;
            _notify();
          }
          return;
        case TtsUtteranceEnd.failed:
          _error ??= result.message ?? 'Could not speak this section.';
          _index++;
          _notify();
      }
    }
    if (!_isCurrent(generation)) return;
    _status = PlaybackStatus.idle;
    _held = false;
    _index = 0;
    _segments = const [];
    _documentId = null;
    _notify();
  }

  Future<bool?> _languageAvailable(int generation, AppLanguage language) async {
    final cached = _availability[language];
    if (cached != null) return cached;
    try {
      final available = await _engine.isAvailable(language);
      if (!_isCurrent(generation)) return null;
      _availability[language] = available;
      return available;
    } on TtsFailure catch (error) {
      _fail(generation, error.message);
      return null;
    }
  }

  void _noteUnavailable(AppLanguage language) {
    _unavailable.add(language);
    final locales = _unavailable.map((item) => item.speechLocale).join(' and ');
    _error = 'Speech for $locales is not available on this device.';
    _notify();
  }

  void _fail(int generation, String message) {
    if (!_isCurrent(generation)) return;
    _status = PlaybackStatus.idle;
    _held = false;
    _error = message;
    _index = 0;
    _segments = const [];
    _documentId = null;
    _notify();
    unawaited(_halt());
  }

  Future<void> _halt() async {
    try {
      await _engine.stop();
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _report(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'playback',
      ),
    );
  }
}
