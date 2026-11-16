import 'package:document_to_podcast/data/flutter_piper_voice_host.dart';
import 'package:flutter_piper_tts/flutter_piper_tts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'quality speech uses dictionary phonemization for Russian and English',
    () {
      expect(
        qualityPhonemizerStrategy,
        PhonemizerStrategy.dictionaryWithNeuralFallback,
      );
    },
  );
}
