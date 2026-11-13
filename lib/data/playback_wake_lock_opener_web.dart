import 'playback_wake_lock.dart';

Future<PlaybackWakeLock> openPlaybackWakeLock() async {
  return const NoopPlaybackWakeLock();
}
