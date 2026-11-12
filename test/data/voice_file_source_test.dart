import 'package:document_to_podcast/data/voice_file_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the full length from a partial content range', () {
    expect(
      voiceContentTotal(
        statusCode: 206,
        contentLength: 10,
        contentRange: 'bytes 10-19/100',
        fromByte: 10,
      ),
      100,
    );
  });

  test('falls back to the resumed offset when the range has no total', () {
    expect(
      voiceContentTotal(
        statusCode: 206,
        contentLength: 10,
        contentRange: 'bytes 10-19/*',
        fromByte: 10,
      ),
      20,
    );
    expect(
      voiceContentTotal(
        statusCode: 206,
        contentLength: -1,
        contentRange: null,
        fromByte: 4,
      ),
      isNull,
    );
  });

  test('uses the content length for a full response', () {
    expect(
      voiceContentTotal(
        statusCode: 200,
        contentLength: 50,
        contentRange: null,
        fromByte: 0,
      ),
      50,
    );
    expect(
      voiceContentTotal(
        statusCode: 200,
        contentLength: -1,
        contentRange: null,
        fromByte: 0,
      ),
      isNull,
    );
  });
}
