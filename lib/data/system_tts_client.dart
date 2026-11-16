/// Platform channel used by [SystemTtsEngine].
abstract interface class SystemTtsClient {
  Future<void> prepare();

  void bindUtterance({
    required void Function() onComplete,
    required void Function() onPause,
    required void Function() onCancel,
    required void Function(Object? message) onError,
  });

  /// Reports spoken ranges for the active utterance when the platform supports
  /// word/boundary callbacks. Pass null to clear.
  void bindProgress(
    void Function(String text, int start, int end, String word)? onProgress,
  );

  Future<Object?> isLanguageAvailable(String language);

  Future<Object?> setLanguage(String language);

  Future<void> setSpeechRate(double rate);

  Future<Object?> speak(String text);

  Future<void> pause();

  Future<void> stop();
}
