import 'package:document_to_podcast/data/playback_position_store.dart';

final class MemoryPlaybackPositionStore implements PlaybackPositionStore {
  final positions = <String, int>{};

  @override
  Future<int?> read(String documentId) async => positions[documentId];

  @override
  Future<void> save(String documentId, int segmentIndex) async {
    positions[documentId] = segmentIndex;
  }

  @override
  Future<void> clear(String documentId) async {
    positions.remove(documentId);
  }
}
