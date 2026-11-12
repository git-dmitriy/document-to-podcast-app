import 'package:document_to_podcast/domain/document_title.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the requested title when it is not blank', () {
    expect(
      resolveDocumentTitle(
        markdown: '# From heading',
        requestedTitle: '  My   note  ',
        sourceName: 'file.md',
      ),
      'My note',
    );
  });

  test('uses the first heading outside a code fence', () {
    expect(
      resolveDocumentTitle(
        markdown: '```\n# Hidden\n```\n\n## Real title\n\nBody',
      ),
      'Real title',
    );
  });

  test('falls back to the file name, then the first line, then Untitled', () {
    expect(
      resolveDocumentTitle(
        markdown: 'Just a paragraph',
        sourceName: r'notes\chapter.markdown',
      ),
      'chapter',
    );
    expect(
      resolveDocumentTitle(markdown: 'Just a paragraph'),
      'Just a paragraph',
    );
    expect(resolveDocumentTitle(markdown: '```\ncode\n```'), 'Untitled');
  });

  test('normalizes a byte order mark and newlines', () {
    expect(normalizeMarkdown('\uFEFF# Title\r\n\r\nLine'), '# Title\n\nLine');
  });
}
