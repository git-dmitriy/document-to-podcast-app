import 'package:wakelock_plus/wakelock_plus.dart';

import 'playback_wake_lock.dart';

Future<PlaybackWakeLock> openPlaybackWakeLock() async {
  return const WakelockPlaybackWakeLock();
}

final class WakelockPlaybackWakeLock implements PlaybackWakeLock {
  const WakelockPlaybackWakeLock();

  @override
  Future<void> enable() => WakelockPlus.enable();

  @override
  Future<void> disable() => WakelockPlus.disable();
}
