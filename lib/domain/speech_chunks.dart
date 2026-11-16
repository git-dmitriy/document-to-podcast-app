const maxSpeechChunkLength = 240;

/// A speakable piece and its character range inside the source [text].
final class SpeechChunkSpan {
  const SpeechChunkSpan({
    required this.text,
    required this.start,
    required this.end,
  });

  final String text;
  final int start;
  final int end;
}

/// Splits narration into short pieces so a long passage can be paused between
/// sentences instead of being synthesized as one block.
List<String> splitSpeechChunks(
  String text, {
  int maxLength = maxSpeechChunkLength,
}) {
  return [
    for (final span in splitSpeechChunkSpans(text, maxLength: maxLength))
      span.text,
  ];
}

/// Like [splitSpeechChunks], but keeps ranges into the whitespace-normalized
/// form of [text] (the same string the chunks are taken from).
List<SpeechChunkSpan> splitSpeechChunkSpans(
  String text, {
  int maxLength = maxSpeechChunkLength,
}) {
  final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return const [];
  final limit = maxLength < 1 ? 1 : maxLength;
  final sentences = <String>[];
  final buffer = StringBuffer();
  for (var index = 0; index < normalized.length; index++) {
    final char = normalized[index];
    buffer.write(char);
    final last = index == normalized.length - 1;
    final boundary =
        _sentenceEnders.contains(char) &&
        (last || normalized[index + 1] == ' ');
    if (!boundary) continue;
    final sentence = buffer.toString().trim();
    buffer.clear();
    if (sentence.isNotEmpty) sentences.add(sentence);
  }
  final tail = buffer.toString().trim();
  if (tail.isNotEmpty) sentences.add(tail);

  final spans = <SpeechChunkSpan>[];
  var cursor = 0;
  for (final sentence in sentences) {
    for (final piece in _fit(sentence, limit)) {
      final start = normalized.indexOf(piece, cursor);
      if (start < 0) continue;
      final end = start + piece.length;
      spans.add(SpeechChunkSpan(text: piece, start: start, end: end));
      cursor = end;
    }
  }
  return spans;
}

const _sentenceEnders = {'.', '!', '?', '…'};

List<String> _fit(String text, int limit) {
  if (text.length <= limit) return [text];
  final pieces = <String>[];
  var rest = text;
  while (rest.length > limit) {
    var cut = rest.lastIndexOf(' ', limit);
    if (cut <= 0) cut = limit;
    final piece = rest.substring(0, cut).trim();
    if (piece.isNotEmpty) pieces.add(piece);
    rest = rest.substring(cut).trim();
  }
  if (rest.isNotEmpty) pieces.add(rest);
  return pieces;
}
