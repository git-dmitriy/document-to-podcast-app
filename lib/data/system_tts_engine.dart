import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/app_language.dart';
import '../domain/tts_engine.dart';
import 'system_tts_client.dart';
import 'system_tts_client_io.dart'
    if (dart.library.html) 'system_tts_client_web.dart'
    as platform;

final class SystemTtsEngine implements TtsEngine {
  SystemTtsEngine({SystemTtsClient? client}) : _injected = client;

  final SystemTtsClient? _injected;
  SystemTtsClient? _client;
  Completer<TtsSpeakResult>? _pending;
  int? _pendingId;
  var _utterance = 0;
  var _prepared = false;
  double _rate = 0.5;
  String? _text;
  AppLanguage? _language;

  @override
  Future<void> warmup() async {
    final client = _open();
    if (_prepared) return;
    try {
      await client.prepare();
      await client.setSpeechRate(_rate);
      _prepared = true;
    } on PlatformException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TtsFailure(
          'System speech is not available on this device.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<bool> isAvailable(AppLanguage language) async {
    await warmup();
    try {
      final value = await _open().isLanguageAvailable(language.speechLocale);
      return _isAffirmative(value);
    } on PlatformException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TtsFailure(
          'System speech is not available on this device.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  @override
  Future<void> setRate(double rate) async {
    if (rate.isNaN) return;
    _rate = rate.clamp(0.0, 1.0).toDouble();
    final client = _client;
    if (client == null || !_prepared) return;
    try {
      await client.setSpeechRate(_rate);
    } on PlatformException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TtsFailure('Could not change the speech speed.', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<TtsSpeakResult> speak(
    String text, {
    required AppLanguage language,
  }) async {
    final spoken = text.trim();
    if (spoken.isEmpty) {
      return const TtsSpeakResult(TtsUtteranceEnd.completed);
    }
    await warmup();
    final client = _open();
    final id = ++_utterance;
    final completer = Completer<TtsSpeakResult>();
    _pending = completer;
    _pendingId = id;
    _text = spoken;
    _language = language;
    client.bindUtterance(
      onComplete: () => _finish(id, TtsUtteranceEnd.completed, null),
      onPause: () => _finish(id, TtsUtteranceEnd.paused, null),
      onCancel: () => _finish(id, TtsUtteranceEnd.cancelled, null),
      onError: (message) {
        _finish(
          id,
          TtsUtteranceEnd.failed,
          message?.toString() ?? 'Could not speak this section.',
        );
      },
    );
    try {
      await client.setSpeechRate(_rate);
      final languageResult = await client.setLanguage(language.speechLocale);
      if (_isNegative(languageResult)) {
        _finish(
          id,
          TtsUtteranceEnd.failed,
          'Speech for ${language.speechLocale} is not available on this device.',
        );
      } else {
        final started = await client.speak(spoken);
        if (_isNegative(started)) {
          _finish(id, TtsUtteranceEnd.failed, 'Could not speak this section.');
        }
      }
    } on PlatformException catch (error) {
      _finish(
        id,
        TtsUtteranceEnd.failed,
        error.message ?? 'Could not speak this section.',
      );
    }
    return completer.future;
  }

  @override
  Future<void> pause() async {
    final client = _client;
    final id = _pendingId;
    if (client == null || id == null) return;
    try {
      await client.pause();
    } on PlatformException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        TtsFailure('Could not pause speech.', cause: error),
        stackTrace,
      );
    }
    _finish(id, TtsUtteranceEnd.paused, null);
  }

  @override
  Future<TtsSpeakResult> resume() {
    final text = _text;
    final language = _language;
    if (text == null || language == null) {
      return Future.value(const TtsSpeakResult(TtsUtteranceEnd.cancelled));
    }
    return speak(text, language: language);
  }

  @override
  Future<void> stop() async {
    final client = _client;
    final id = _pendingId;
    _text = null;
    _language = null;
    if (client == null) {
      _finish(id, TtsUtteranceEnd.cancelled, null);
      return;
    }
    try {
      await client.stop();
    } on PlatformException catch (error, stackTrace) {
      _finish(id, TtsUtteranceEnd.cancelled, null);
      Error.throwWithStackTrace(
        TtsFailure('Could not stop speech.', cause: error),
        stackTrace,
      );
    }
    _finish(id, TtsUtteranceEnd.cancelled, null);
  }

  SystemTtsClient _open() =>
      _client ??= _injected ?? platform.createSystemTtsClient();

  void _finish(int? id, TtsUtteranceEnd end, String? message) {
    if (id == null || _pendingId != id) return;
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    pending.complete(TtsSpeakResult(end, message: message));
  }
}

bool _isNegative(Object? value) {
  if (value is bool) return !value;
  if (value is num) return value == 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    return normalized == '0' || normalized == 'false';
  }
  return false;
}

bool _isAffirmative(Object? value) {
  if (value == null) return false;
  return !_isNegative(value);
}
