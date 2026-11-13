import 'audio_cache.dart';
import 'memory_audio_cache.dart';

Future<AudioCache> openAudioCache() async {
  return MemoryAudioCache();
}
