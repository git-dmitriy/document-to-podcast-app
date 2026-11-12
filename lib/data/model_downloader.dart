import '../domain/voice_install.dart';
import '../domain/voice_package.dart';

abstract interface class ModelDownloader {
  Future<List<VoiceInstall>> inspect();

  Future<void> download(
    VoiceId id, {
    required void Function(VoiceDownloadProgress progress) onProgress,
  });

  void cancel(VoiceId id);

  Future<void> delete(VoiceId id);
}
