import '../domain/tts_engine.dart';
import 'model_downloader.dart';
import 'system_tts_engine.dart';

TtsEngine createQualityEngine(ModelDownloader _) {
  return SystemTtsEngine();
}
