abstract interface class QualityPromptStore {
  Future<bool> isDismissed();

  Future<void> dismiss();
}
