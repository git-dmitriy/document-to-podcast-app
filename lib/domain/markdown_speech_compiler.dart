import 'package:markdown/markdown.dart';

import 'document_title.dart';
import 'language_detector.dart';
import 'speech_plan.dart';
import 'speech_segment.dart';

/// Compiles Markdown into speakable segments.
///
/// Markup is removed. Each block is its own segment so playback can pause
/// between blocks. Fenced code, tables, and thematic breaks become
/// [SpeechSegmentKind.skip].
final class MarkdownSpeechCompiler {
  const MarkdownSpeechCompiler({LanguageDetector? languages})
    : _languages = languages ?? const LanguageDetector();

  final LanguageDetector _languages;

  SpeechPlan compile(String markdown) {
    final document = Document(
      extensionSet: ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );
    final nodes = document.parse(normalizeMarkdown(markdown));
    final visitor = _ReadingVisitor();
    for (final node in nodes) {
      node.accept(visitor);
    }
    return visitor.toPlan(_languages);
  }
}

final class _Draft {
  const _Draft(this.kind, this.text);

  final SpeechSegmentKind kind;
  final String text;
}

final class _ReadingVisitor implements NodeVisitor {
  final _drafts = <_Draft>[];
  var _depth = 0;

  SpeechPlan toPlan(LanguageDetector languages) {
    final spoken = [
      for (final draft in _drafts)
        if (draft.kind != SpeechSegmentKind.skip) draft.text,
    ].join('\n');
    final documentLanguage = languages.detect(spoken);
    return SpeechPlan(
      segments: [
        for (final draft in _drafts)
          SpeechSegment(
            text: draft.text,
            language: draft.kind == SpeechSegmentKind.skip
                ? documentLanguage
                : languages.detect(
                    draft.text,
                    documentLanguage: documentLanguage,
                  ),
            kind: draft.kind,
          ),
      ],
    );
  }

  @override
  bool visitElementBefore(Element element) {
    _depth++;
    if (element.tag == 'pre' || element.tag == 'table' || element.tag == 'hr') {
      _drafts.add(const _Draft(SpeechSegmentKind.skip, ''));
      _depth--;
      return false;
    }

    final kind = switch (element.tag) {
      'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6' => SpeechSegmentKind.heading,
      'p' => SpeechSegmentKind.paragraph,
      'li' => SpeechSegmentKind.listItem,
      _ => null,
    };
    if (kind == null) return true;

    final text = _plainText(element);
    if (text.isNotEmpty) {
      _drafts.add(_Draft(kind, text));
    }
    for (final child in element.children ?? const <Node>[]) {
      if (child is Element && _isNestedBlock(child)) {
        child.accept(this);
      }
    }
    _depth--;
    return false;
  }

  @override
  void visitElementAfter(Element element) {
    _depth--;
  }

  @override
  void visitText(Text text) {
    if (_depth != 0 || text.text.trim().isEmpty) return;
    _drafts.add(const _Draft(SpeechSegmentKind.skip, ''));
  }
}

bool _isNestedBlock(Element element) {
  return switch (element.tag) {
    'ul' || 'ol' || 'pre' || 'table' || 'blockquote' || 'section' => true,
    _ => false,
  };
}

String _plainText(Element element) {
  final buffer = StringBuffer();
  for (final child in element.children ?? const <Node>[]) {
    _appendInline(buffer, child);
  }
  return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

void _appendInline(StringBuffer buffer, Node node) {
  if (node is Text) {
    buffer.write(node.text);
    return;
  }
  if (node is! Element || _isNestedBlock(node)) return;

  switch (node.tag) {
    case 'br' || 'hr':
      buffer.write(' ');
    case 'img':
      final alt = node.attributes['alt']?.trim() ?? '';
      if (alt.isNotEmpty) buffer.write(alt);
    case 'script' || 'style':
      return;
    case 'sup' when node.attributes['class'] == 'footnote-ref':
      return;
    case 'a' when node.attributes['class'] == 'footnote-backref':
      return;
    case 'a':
      final label = StringBuffer();
      for (final child in node.children ?? const <Node>[]) {
        _appendInline(label, child);
      }
      final text = label.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty || _isUrl(text)) return;
      buffer.write(text);
    default:
      for (final child in node.children ?? const <Node>[]) {
        _appendInline(buffer, child);
      }
  }
}

bool _isUrl(String text) {
  final value = text.trim().toLowerCase();
  return value.startsWith('http://') ||
      value.startsWith('https://') ||
      value.startsWith('mailto:');
}
