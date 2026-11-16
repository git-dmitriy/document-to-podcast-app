import '../domain/tts_engine.dart';
import 'audio_cache.dart';
import 'flutter_piper_voice_host.dart';
import 'model_downloader.dart';
import 'piper_tts_engine.dart';
import 'routing_tts_engine.dart';
import 'system_tts_engine.dart';

TtsEngine createQualityEngine(ModelDownloader voices, AudioCache cache) {
  return RoutingTtsEngine(
    quality: PiperTtsEngine(
      voices: voices,
      host: FlutterPiperVoiceHost(),
      cache: cache,
    ),
    system: SystemTtsEngine(),
  );
}
