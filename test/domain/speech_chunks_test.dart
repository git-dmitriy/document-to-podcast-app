import 'package:document_to_podcast/domain/speech_chunks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps short sentences intact', () {
    expect(splitSpeechChunks('Hello. World!'), ['Hello.', 'World!']);
    expect(splitSpeechChunks('   '), isEmpty);
  });

  test('splits a long sentence on spaces', () {
    final text = List.filled(30, 'word').join(' ');
    final chunks = splitSpeechChunks(text, maxLength: 40);

    expect(chunks.length, greaterThan(1));
    expect(chunks.every((chunk) => chunk.length <= 40), isTrue);
    expect(chunks.join(' '), text);
  });
}
