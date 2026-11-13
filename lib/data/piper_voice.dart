abstract interface class PiperVoiceClient {
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
