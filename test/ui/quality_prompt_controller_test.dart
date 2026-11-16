import 'package:document_to_podcast/data/memory_quality_prompt_store.dart';
import 'package:document_to_podcast/ui/library/quality_prompt_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads and dismisses the quality prompt', () async {
    final store = MemoryQualityPromptStore();
    final controller = QualityPromptController(store: store);
    addTearDown(controller.dispose);

    expect(controller.isLoading, isTrue);
    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.isDismissed, isFalse);

    await controller.dismiss();

    expect(controller.isDismissed, isTrue);
    expect(store.dismissed, isTrue);
  });
}
