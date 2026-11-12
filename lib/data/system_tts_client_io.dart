import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';

import 'system_tts_client.dart';

SystemTtsClient createSystemTtsClient() => IoSystemTtsClient();

final class IoSystemTtsClient implements SystemTtsClient {
  IoSystemTtsClient({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  var _prepared = false;

  @override
  Future<void> prepare() async {
    if (_prepared) return;
    await _tts.awaitSpeakCompletion(false);
    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
    }
    _prepared = true;
  }

  @override
  void bindUtterance({
    required void Function() onComplete,
    required void Function() onPause,
    required void Function() onCancel,
    required void Function(Object? message) onError,
  }) {
    _tts.setCompletionHandler(onComplete);
    _tts.setPauseHandler(onPause);
    _tts.setCancelHandler(onCancel);
    _tts.setErrorHandler((message) {
      onError(message is Object ? message : null);
    });
  }

  @override
  Future<Object?> isLanguageAvailable(String language) {
    return _value(_tts.isLanguageAvailable(language));
  }

  @override
  Future<Object?> setLanguage(String language) {
    return _value(_tts.setLanguage(language));
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }

  @override
  Future<Object?> speak(String text) => _value(_tts.speak(text));

  @override
  Future<void> pause() async {
    await _tts.pause();
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}

Future<Object?> _value(Future<dynamic> result) async {
  final value = await result;
  return value is Object ? value : null;
}
