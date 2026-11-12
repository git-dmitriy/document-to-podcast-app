String normalizeMarkdown(String markdown) {
  final withoutBom = markdown.startsWith('\uFEFF')
      ? markdown.substring(1)
      : markdown;
  return withoutBom.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

String resolveDocumentTitle({
  required String markdown,
  String requestedTitle = '',
  String? sourceName,
}) {
  final requested = _collapseWhitespace(requestedTitle);
  if (requested.isNotEmpty) return _cap(requested, 200);

  final heading = _firstHeading(markdown);
  if (heading != null) return _cap(heading, 200);

  final fromFile = sourceName == null ? '' : _titleFromFileName(sourceName);
  if (fromFile.isNotEmpty) return _cap(fromFile, 200);

  final line = _firstPlainLine(markdown);
  if (line != null) return _cap(line, 120);

  return 'Untitled';
}

String? _firstHeading(String markdown) {
  final heading = RegExp(r'^#{1,6}[ \t]+(\S.*?)\s*$');
  var inFence = false;
  for (final line in markdown.split('\n')) {
    final trimmed = line.trim();
    if (_isFence(trimmed)) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;
    final match = heading.firstMatch(trimmed);
    final text = match?.group(1);
    if (text != null && text.isNotEmpty) return text;
  }
  return null;
}

String? _firstPlainLine(String markdown) {
  var inFence = false;
  for (final line in markdown.split('\n')) {
    final trimmed = line.trim();
    if (_isFence(trimmed)) {
      inFence = !inFence;
      continue;
    }
    if (inFence || trimmed.isEmpty || _isThematicBreak(trimmed)) continue;
    if (RegExp(r'^#{1,6}(\s|$)').hasMatch(trimmed)) continue;
    return trimmed;
  }
  return null;
}

bool _isFence(String trimmed) {
  return trimmed.startsWith('```') || trimmed.startsWith('~~~');
}

bool _isThematicBreak(String trimmed) {
  return RegExp(r'^(\*\s*){3,}$').hasMatch(trimmed) ||
      RegExp(r'^(-\s*){3,}$').hasMatch(trimmed) ||
      RegExp(r'^(_\s*){3,}$').hasMatch(trimmed);
}

String _titleFromFileName(String name) {
  final base = name.split(RegExp(r'[\\/]')).last.trim();
  final lower = base.toLowerCase();
  final String stripped;
  if (lower.endsWith('.markdown')) {
    stripped = base.substring(0, base.length - '.markdown'.length);
  } else if (lower.endsWith('.md')) {
    stripped = base.substring(0, base.length - 3);
  } else {
    stripped = base;
  }
  return _collapseWhitespace(stripped);
}

String _collapseWhitespace(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ');
}

String _cap(String value, int max) {
  if (value.length <= max) return value;
  return value.substring(0, max).trimRight();
}
