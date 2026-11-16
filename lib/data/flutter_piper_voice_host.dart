import 'dart:typed_data';

import 'package:flutter_piper_tts/flutter_piper_tts.dart';

import 'piper_voice.dart';

const qualityPhonemizerStrategy =
    PhonemizerStrategy.dictionaryWithNeuralFallback;

final class FlutterPiperVoiceHost implements PiperVoiceHost {
  @override
  Future<PiperVoiceClient> open({
    required String modelPath,
    required String configPath,
  }) async {
    final voice = await PiperTTS.create(
      modelPath: modelPath,
      configPath: configPath,
    );
    return _FlutterPiperVoice(voice);
  }
}

final class _FlutterPiperVoice implements PiperVoiceClient {
  _FlutterPiperVoice(this._voice);

  final PiperTTS _voice;
  var _disposed = false;

  @override
  bool get canPlayRenderedAudio => false;

  @override
  Future<Uint8List?> render(String text) async => null;

  @override
  Future<void> play(Uint8List audio) async {}

  @override
  Future<void> speak(String text) {
    return _voice.speak(
      text,
      waitForCompletion: true,
      phonemizerStrategy: qualityPhonemizerStrategy,
    );
  }

  @override
  Future<void> pause() => _voice.pause();

  @override
  Future<void> resume() => _voice.resume();

  @override
  Future<void> stop() => _voice.stop();

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _voice.dispose();
  }
}
