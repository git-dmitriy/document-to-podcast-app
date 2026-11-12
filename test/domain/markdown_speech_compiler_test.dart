import 'package:document_to_podcast/domain/app_language.dart';
import 'package:document_to_podcast/domain/markdown_speech_compiler.dart';
import 'package:document_to_podcast/domain/speech_segment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const compiler = MarkdownSpeechCompiler();

  SpeechSegment spoken(
    String text,
    SpeechSegmentKind kind, [
    AppLanguage language = AppLanguage.en,
  ]) {
    return SpeechSegment(text: text, language: language, kind: kind);
  }

  const skip = SpeechSegment(
    text: '',
    language: AppLanguage.en,
    kind: SpeechSegmentKind.skip,
  );

  test('splits blocks, strips markup, and skips code and tables', () {
    final plan = compiler.compile('''
# Title

Hello **world** and `code`.

- one
- [x] two

> quoted

```
secret code
```

| a | b |
| - | - |
| 1 | 2 |

See [the docs](https://example.com).

https://example.com

---

Next.
''');

    expect(plan.segments, [
      spoken('Title', SpeechSegmentKind.heading),
      spoken('Hello world and code.', SpeechSegmentKind.paragraph),
      spoken('one', SpeechSegmentKind.listItem),
      spoken('two', SpeechSegmentKind.listItem),
      spoken('quoted', SpeechSegmentKind.paragraph),
      skip,
      skip,
      spoken('See the docs.', SpeechSegmentKind.paragraph),
      skip,
      spoken('Next.', SpeechSegmentKind.paragraph),
    ]);
  });

  test('assigns each segment its own language and inherits the document', () {
    final plan = compiler.compile('''
# Заголовок

Hello

123
''');

    expect(plan.segments, [
      spoken('Заголовок', SpeechSegmentKind.heading, AppLanguage.ru),
      spoken('Hello', SpeechSegmentKind.paragraph, AppLanguage.en),
      spoken('123', SpeechSegmentKind.paragraph, AppLanguage.ru),
    ]);
  });

  test('speaks a nested list and an image description', () {
    final plan = compiler.compile('''
- parent
  - child

Picture: ![a cat](https://example.com/cat.png)
''');

    expect(plan.segments.map((segment) => segment.text), [
      'parent',
      'child',
      'Picture: a cat',
    ]);
  });

  test(
    'speaks a footnote without its marker and ignores an empty document',
    () {
      final plan = compiler.compile('''
Word[^1].

[^1]: Note text.
''');

      expect(plan.segments.map((segment) => segment.text), [
        'Word.',
        'Note text.',
      ]);
      expect(compiler.compile('   \n').segments, isEmpty);
    },
  );
}
