import 'audio_cache.dart';
import 'audio_cache_opener_io.dart'
    if (dart.library.html) 'audio_cache_opener_web.dart'
    as opener;

Future<AudioCache> openAudioCache() => opener.openAudioCache();
