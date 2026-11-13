abstract interface class PlaybackPositionStore {
  Future<int?> read(String documentId);

  Future<void> save(String documentId, int segmentIndex);

  Future<void> clear(String documentId);
}
