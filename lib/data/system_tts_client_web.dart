import 'package:flutter/services.dart';

import 'system_tts_client.dart';

SystemTtsClient createSystemTtsClient() => WebSystemTtsClient();

final class WebSystemTtsClient implements SystemTtsClient {
  static const MethodChannel _channel = MethodChannel('flutter_tts');

  void Function()? _onComplete;
  void Function()? _onPause;
  void Function()? _onCancel;
  void Function(Object? message)? _onError;
  var _prepared = false;

  @override
  Future<void> prepare() async {
    if (_prepared) return;
    _channel.setMethodCallHandler(_onPlatform);
    await _channel.invokeMethod<Object?>('awaitSpeakCompletion', false);
    _prepared = true;
  }

  @override
  void bindUtterance({
    required void Function() onComplete,
    required void Function() onPause,
    required void Function() onCancel,
    required void Function(Object? message) onError,
  }) {
    _onComplete = onComplete;
    _onPause = onPause;
    _onCancel = onCancel;
    _onError = onError;
  }

  @override
  Future<Object?> isLanguageAvailable(String language) {
    return _channel.invokeMethod<Object?>('isLanguageAvailable', language);
  }

  @override
  Future<Object?> setLanguage(String language) {
    return _channel.invokeMethod<Object?>('setLanguage', language);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    // Browser speech uses 1.0 as normal. The shared slider uses 0.5.
    final browserRate = (0.5 + rate.clamp(0.0, 1.0)).toDouble();
    await _channel.invokeMethod<Object?>('setSpeechRate', browserRate);
  }

  @override
  Future<Object?> speak(String text) {
    return _channel.invokeMethod<Object?>('speak', text);
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod<Object?>('pause');
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod<Object?>('stop');
  }

  Future<void> _onPlatform(MethodCall call) async {
    switch (call.method) {
      case 'speak.onComplete':
        _onComplete?.call();
      case 'speak.onPause':
        _onPause?.call();
      case 'speak.onCancel':
        _onCancel?.call();
      case 'speak.onError':
        final arguments = call.arguments;
        _onError?.call(arguments is Object ? arguments : null);
      default:
        break;
    }
  }
}
