import 'dart:io';
import 'dart:typed_data';

import '../domain/audio_cache_key.dart';
import 'audio_cache.dart';

final class FileAudioCache implements AudioCache {
  FileAudioCache(this._directory);

  final Directory _directory;

  @override
  Future<Uint8List?> read(AudioCacheKey key) async {
    try {
      for (final extension in const ['wav', 'pcm']) {
        final file = _file(key, extension);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) continue;
        return bytes;
      }
      return null;
    } on IOException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AudioCacheException('Could not read cached audio.', cause: error),
        stackTrace,
      );
    }
  }

  @override
  Future<void> write(AudioCacheKey key, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final extension = looksLikeWav(bytes) ? 'wav' : 'pcm';
    final other = extension == 'wav' ? 'pcm' : 'wav';
    final partial = _file(key, 'partial');
    final target = _file(key, extension);
    try {
      await _directory.create(recursive: true);
      await partial.writeAsBytes(bytes, flush: true);
      final stale = _file(key, other);
      if (await stale.exists()) await stale.delete();
      if (await target.exists()) await target.delete();
      await partial.rename(target.path);
    } on IOException catch (error, stackTrace) {
      try {
        if (await partial.exists()) await partial.delete();
      } on IOException {
        // Report the write that failed.
      }
      Error.throwWithStackTrace(
        AudioCacheException('Could not store cached audio.', cause: error),
        stackTrace,
      );
    }
  }

  File _file(AudioCacheKey key, String extension) {
    return File('${_directory.path}/${key.digest}.$extension');
  }
}
