abstract interface class PlaybackWakeLock {
  Future<void> enable();

  Future<void> disable();
}

final class NoopPlaybackWakeLock implements PlaybackWakeLock {
  const NoopPlaybackWakeLock();

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
}
