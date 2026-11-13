import 'dart:typed_data';

abstract interface class PiperVoiceClient {
  /// True when [render] returns audio that [play] can speak.
  bool get canPlayRenderedAudio;

  Future<Uint8List?> render(String text);

  Future<void> play(Uint8List audio);

  Future<void> speak(String text);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}

abstract interface class PiperVoiceHost {
  Future<PiperVoiceClient> open({
    required String modelPath,
    required String configPath,
  });
}
