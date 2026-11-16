import 'package:shared_preferences/shared_preferences.dart';

import 'async_lock.dart';
import 'playback_position_codec.dart';
import 'playback_position_store.dart';

final class PreferencesPlaybackPositionStore implements PlaybackPositionStore {
  PreferencesPlaybackPositionStore(this._preferences);

  final SharedPreferences _preferences;
  final AsyncLock _lock = AsyncLock();

  @override
  Future<int?> read(String documentId) {
    return _lock.run(() async => _read()[documentId]);
  }

  @override
  Future<void> save(String documentId, int segmentIndex) {
    return _lock.run(() async {
      if (segmentIndex < 0) return;
      final positions = _read();
      positions[documentId] = segmentIndex;
      await _write(positions);
    });
  }

  @override
  Future<void> clear(String documentId) {
    return _lock.run(() async {
      final positions = _read();
      if (positions.remove(documentId) == null) return;
      await _write(positions);
    });
  }

  Map<String, int> _read() {
    return decodePlaybackPositions(
      _preferences.getString(playbackPositionsKey),
    );
  }

  Future<void> _write(Map<String, int> positions) {
    return _preferences.setString(
      playbackPositionsKey,
      encodePlaybackPositions(positions),
    );
  }
}
