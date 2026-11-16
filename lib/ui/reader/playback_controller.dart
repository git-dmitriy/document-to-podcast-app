import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/async_lock.dart';
import '../../data/playback_position_store.dart';
import '../../data/playback_wake_lock.dart';
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
    this._positions,
    this._wakeLock,
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

  final AsyncLock _engineLock = AsyncLock();
  final AsyncLock _wakeGate = AsyncLock();
  TtsEngine _engine;
  final PlaybackPositionStore? _positions;
  final PlaybackWakeLock? _wakeLock;
  final Set<String> _forgotten = {};
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
  var _wakeHeld = false;

  /// High-frequency spoken range inside [currentSegment]. Listeners of this
  /// notifier must not rebuild the whole document body.
  final ValueNotifier<TtsUtteranceProgress?> utteranceHighlight =
      ValueNotifier<TtsUtteranceProgress?>(null);

  PlaybackStatus get status => _status;

  String? get documentId => _documentId;

  String? get errorMessage => _error;

  double get rate => _rate;

  int? get segmentIndex =>
      _status == PlaybackStatus.idle || _segments.isEmpty ? null : _index;

  SpeechSegment? get currentSegment {
    final index = segmentIndex;
    if (index == null || index < 0 || index >= _segments.length) return null;
    return _segments[index];
  }

  List<SpeechSegment> get segments => _segments;

  bool get canSkipBackward =>
      _status != PlaybackStatus.idle && _segments.isNotEmpty && _index > 0;

  bool get canSkipForward =>
      _status != PlaybackStatus.idle &&
      _segments.isNotEmpty &&
      _index + 1 < _segments.length;

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
    _forgotten.remove(document.id);
    final saved = await _readPosition(document.id);
    if (!_isCurrent(generation)) return;
    final start = saved != null && saved < segments.length ? saved : 0;
    _segments = List.unmodifiable(segments);
    _index = start;
    _documentId = document.id;
    _held = false;
    _status = PlaybackStatus.playing;
    _error = null;
    _notify();
    await _savePosition(document.id, start);
    if (!_isCurrent(generation)) return;
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
      _clearHighlight();
      _notify();
      return;
    }
    final id = _documentId;
    if (id != null) await _savePosition(id, _index);
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
    _clearHighlight();
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

  Future<void> skipBackward() => _skip(-1);

  Future<void> skipForward() => _skip(1);

  Future<void> forget(String documentId) {
    _forgotten.add(documentId);
    return _clearPosition(documentId);
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

  Future<void> useEngine(TtsEngine engine) {
    return _engineLock.run(() async {
      if (_disposed || identical(engine, _engine)) {
        if (!identical(engine, _engine)) await engine.dispose();
        return;
      }
      await stop();
      if (_disposed) {
        await engine.dispose();
        return;
      }
      final previous = _engine;
      _engine = engine;
      _availability.clear();
      _unavailable.clear();
      try {
        await engine.setRate(_rate);
        await engine.warmup();
      } on TtsFailure catch (error) {
        _error = error.message;
        _notify();
      }
      try {
        await previous.dispose();
      } catch (error, stackTrace) {
        _report(error, stackTrace);
      }
    });
  }

  @override
  void dispose() {
    final active = _status != PlaybackStatus.idle || _held;
    _disposed = true;
    _generation++;
    _status = PlaybackStatus.idle;
    _clearHighlight();
    utteranceHighlight.dispose();
    unawaited(_release(active));
    super.dispose();
  }

  Future<void> _release(bool active) async {
    await _syncWake();
    if (active) await _halt();
    try {
      await _engine.dispose();
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
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
      _clearHighlight();
      final onProgress = _progressHandler(generation, segment.text);
      final TtsSpeakResult result;
      try {
        result = resume
            ? await _engine.resume(onProgress: onProgress)
            : await _engine.speak(
                segment.text,
                language: segment.language,
                onProgress: onProgress,
              );
      } on TtsFailure catch (error) {
        _fail(generation, error.message);
        return;
      }
      resume = false;
      if (!_isCurrent(generation)) return;
      switch (result.end) {
        case TtsUtteranceEnd.completed:
          _index++;
          _clearHighlight();
          final id = _documentId;
          if (id != null && _index < _segments.length) {
            await _savePosition(id, _index);
          }
          if (!_isCurrent(generation)) return;
          _notify();
          if (_status != PlaybackStatus.playing) return;
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
            _clearHighlight();
            _notify();
          }
          return;
        case TtsUtteranceEnd.failed:
          _error ??= result.message ?? 'Could not speak this section.';
          _index++;
          _clearHighlight();
          _notify();
      }
    }
    if (!_isCurrent(generation)) return;
    final id = _documentId;
    _status = PlaybackStatus.idle;
    _held = false;
    _index = 0;
    _segments = const [];
    _documentId = null;
    _clearHighlight();
    _notify();
    if (id != null) await _savePosition(id, 0);
  }

  TtsProgressHandler _progressHandler(int generation, String text) {
    return (progress) {
      if (!_isCurrent(generation) || _disposed) return;
      final start = progress.start.clamp(0, text.length);
      final end = progress.end.clamp(start, text.length);
      if (end <= start) return;
      final next = TtsUtteranceProgress(start: start, end: end);
      if (utteranceHighlight.value == next) return;
      utteranceHighlight.value = next;
    };
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
    _clearHighlight();
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

  Future<void> _skip(int delta) async {
    if (_disposed || _status == PlaybackStatus.idle || _segments.isEmpty) {
      return;
    }
    final next = _index + delta;
    if (next < 0 || next >= _segments.length) return;
    final generation = ++_generation;
    final id = _documentId;
    final paused = _status == PlaybackStatus.paused;
    _index = next;
    _held = false;
    _error = null;
    _clearHighlight();
    if (id != null) await _savePosition(id, next);
    if (!_isCurrent(generation)) return;
    if (paused) {
      _notify();
      return;
    }
    _status = PlaybackStatus.playing;
    _notify();
    try {
      await _engine.stop();
    } on TtsFailure catch (error) {
      _fail(generation, error.message);
      return;
    } catch (error, stackTrace) {
      _report(error, stackTrace);
      _fail(generation, 'Playback failed.');
      return;
    }
    if (!_isCurrent(generation) || _status != PlaybackStatus.playing) return;
    await _drain(generation);
  }

  Future<int?> _readPosition(String id) async {
    final store = _positions;
    if (store == null || _forgotten.contains(id)) return null;
    try {
      return await store.read(id);
    } catch (error, stackTrace) {
      _report(error, stackTrace);
      return null;
    }
  }

  Future<void> _savePosition(String id, int index) async {
    final store = _positions;
    if (store == null || index < 0 || _forgotten.contains(id)) return;
    try {
      await store.save(id, index);
    } catch (error, stackTrace) {
      _report(error, stackTrace);
      return;
    }
    if (_forgotten.contains(id)) await _clearPosition(id);
  }

  Future<void> _clearPosition(String id) async {
    final store = _positions;
    if (store == null) return;
    try {
      await store.clear(id);
    } catch (error, stackTrace) {
      _report(error, stackTrace);
    }
  }

  Future<void> _syncWake() {
    final lock = _wakeLock;
    if (lock == null) return Future<void>.value();
    final enabled = !_disposed && _status == PlaybackStatus.playing;
    return _wakeGate.run(() async {
      if (_wakeHeld == enabled) return;
      try {
        if (enabled) {
          await lock.enable();
        } else {
          await lock.disable();
        }
        _wakeHeld = enabled;
      } catch (error, stackTrace) {
        _report(error, stackTrace);
      }
    });
  }

  void _notify() {
    if (_disposed) return;
    unawaited(_syncWake());
    notifyListeners();
  }

  void _clearHighlight() {
    if (utteranceHighlight.value != null) {
      utteranceHighlight.value = null;
    }
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
