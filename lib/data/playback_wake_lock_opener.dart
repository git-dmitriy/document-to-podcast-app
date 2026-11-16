import 'playback_wake_lock.dart';
import 'playback_wake_lock_opener_io.dart'
    if (dart.library.html) 'playback_wake_lock_opener_web.dart'
    as opener;

Future<PlaybackWakeLock> openPlaybackWakeLock() =>
    opener.openPlaybackWakeLock();
