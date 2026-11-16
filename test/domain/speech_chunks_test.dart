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

  test('keeps character ranges for each chunk', () {
    const text = 'Hello. World!';
    final spans = splitSpeechChunkSpans(text);

    expect(spans.map((span) => span.text), ['Hello.', 'World!']);
    expect(text.substring(spans[0].start, spans[0].end), 'Hello.');
    expect(text.substring(spans[1].start, spans[1].end), 'World!');
  });
}
