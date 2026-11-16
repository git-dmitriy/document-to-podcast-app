import 'quality_prompt_store.dart';

final class MemoryQualityPromptStore implements QualityPromptStore {
  MemoryQualityPromptStore({this.dismissed = false});

  bool dismissed;

  @override
  Future<bool> isDismissed() async => dismissed;

  @override
  Future<void> dismiss() async {
    dismissed = true;
  }
}
