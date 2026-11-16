import 'dart:typed_data';

import '../domain/audio_cache_key.dart';

abstract interface class AudioCache {
  Future<Uint8List?> read(AudioCacheKey key);

  Future<void> write(AudioCacheKey key, Uint8List bytes);
}

final class AudioCacheException implements Exception {
  const AudioCacheException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
