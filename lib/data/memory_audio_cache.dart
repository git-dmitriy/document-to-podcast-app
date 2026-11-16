import 'dart:typed_data';

import '../domain/audio_cache_key.dart';
import 'audio_cache.dart';

final class MemoryAudioCache implements AudioCache {
  final stored = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(AudioCacheKey key) async {
    final bytes = stored[key.digest];
    if (bytes == null || bytes.isEmpty) return null;
    return Uint8List.fromList(bytes);
  }

  @override
  Future<void> write(AudioCacheKey key, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    stored[key.digest] = Uint8List.fromList(bytes);
  }
}
