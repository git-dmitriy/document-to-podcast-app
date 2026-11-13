import '../domain/tts_engine.dart';
import 'flutter_piper_voice_host.dart';
import 'model_downloader.dart';
import 'piper_tts_engine.dart';
import 'routing_tts_engine.dart';
import 'system_tts_engine.dart';

TtsEngine createQualityEngine(ModelDownloader voices) {
  return RoutingTtsEngine(
    quality: PiperTtsEngine(voices: voices, host: FlutterPiperVoiceHost()),
    system: SystemTtsEngine(),
  );
}
