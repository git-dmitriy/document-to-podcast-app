import 'dart:convert';

import 'package:document_to_podcast/data/document_store_exception.dart';
import 'package:document_to_podcast/data/markdown_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes a Markdown file', () {
    expect(
      decodeMarkdownFile(
        name: 'notes/Chapter.MD',
        bytes: utf8.encode('# Chapter'),
      ),
      '# Chapter',
    );
  });

  test('rejects other extensions and invalid UTF-8', () {
    expect(
      () => decodeMarkdownFile(name: 'notes.txt', bytes: utf8.encode('text')),
      throwsA(isA<DocumentStoreException>()),
    );
    expect(
      () => decodeMarkdownFile(name: 'notes.md', bytes: [0xFF, 0xFE]),
      throwsA(
        isA<DocumentStoreException>().having(
          (error) => error.message,
          'message',
          'The file is not valid UTF-8.',
        ),
      ),
    );
  });
}
