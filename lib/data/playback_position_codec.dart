import 'dart:convert';

import 'document_id.dart';

const playbackPositionsKey = 'playback_positions_v1';
const playbackPositionsVersion = 1;

String encodePlaybackPositions(Map<String, int> positions) {
  return jsonEncode({
    'version': playbackPositionsVersion,
    'positions': positions,
  });
}

Map<String, int> decodePlaybackPositions(String? source) {
  if (source == null || source.trim().isEmpty) return {};
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map) return {};
    if (decoded['version'] != playbackPositionsVersion) return {};
    final raw = decoded['positions'];
    if (raw is! Map) return {};
    final positions = <String, int>{};
    for (final entry in raw.entries) {
      final id = entry.key;
      final index = entry.value;
      if (id is! String || !documentIdPattern.hasMatch(id)) continue;
      if (index is! int || index < 0) continue;
      positions[id] = index;
    }
    return positions;
  } on FormatException {
    return {};
  }
}
