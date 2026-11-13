import 'dart:io';
import 'dart:typed_data';

import 'package:document_to_podcast/data/file_audio_cache.dart';
import 'package:document_to_podcast/domain/audio_cache_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('audio-cache-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('changes the digest when the text, voice, rate, or engine changes', () {
    const base = AudioCacheKey(
      text: 'Hello',
      voice: 'lessac',
      rate: 0.5,
      engine: 'quality',
    );

    expect(base.digest, isNotEmpty);
    expect(
      const AudioCacheKey(
        text: 'Hello',
        voice: 'lessac',
        rate: 0.5,
        engine: 'quality',
      ).digest,
      base.digest,
    );
    expect(
      const AudioCacheKey(
        text: 'Hello',
        voice: 'irina',
        rate: 0.5,
        engine: 'quality',
      ).digest,
      isNot(base.digest),
    );
    expect(
      const AudioCacheKey(
        text: 'Hello',
        voice: 'lessac',
        rate: 0.8,
        engine: 'quality',
      ).digest,
      isNot(base.digest),
    );
    expect(
      const AudioCacheKey(
        text: 'Hello there',
        voice: 'lessac',
        rate: 0.5,
        engine: 'quality',
      ).digest,
      isNot(base.digest),
    );
    expect(
      const AudioCacheKey(
        text: 'Hello',
        voice: 'lessac',
        rate: 0.5,
        engine: 'system',
      ).digest,
      isNot(base.digest),
    );
  });

  test('stores wav and pcm without keeping a partial file', () async {
    final cache = FileAudioCache(root);
    const key = AudioCacheKey(
      text: 'Hello',
      voice: 'lessac',
      rate: 0.5,
      engine: 'quality',
    );
    final wav = Uint8List.fromList([
      0x52,
      0x49,
      0x46,
      0x46,
      0,
      0,
      0,
      0,
      0x57,
      0x41,
      0x56,
      0x45,
      9,
    ]);

    await cache.write(key, wav);
    expect(await cache.read(key), wav);
    expect(File('${root.path}/${key.digest}.wav').existsSync(), isTrue);
    expect(File('${root.path}/${key.digest}.partial').existsSync(), isFalse);

    await cache.write(key, Uint8List.fromList(const [1, 2, 3, 4]));
    expect(await cache.read(key), Uint8List.fromList(const [1, 2, 3, 4]));
    expect(File('${root.path}/${key.digest}.wav').existsSync(), isFalse);
    expect(File('${root.path}/${key.digest}.pcm').existsSync(), isTrue);
    expect(await cache.read(key), isNot(wav));
  });
}
