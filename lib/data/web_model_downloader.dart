import '../domain/voice_install.dart';
import '../domain/voice_package.dart';
import 'model_downloader.dart';
import 'voice_download_exception.dart';

final class WebModelDownloader implements ModelDownloader {
  const WebModelDownloader();

  static const unavailableMessage =
      'Quality voices cannot be downloaded in the browser.';

  @override
  Future<List<VoiceInstall>> inspect() async {
    return [
      for (final voice in voiceCatalog)
        VoiceInstall(id: voice.id, status: VoiceInstallStatus.missing),
    ];
  }

  @override
  Future<void> download(
    VoiceId id, {
    required void Function(VoiceDownloadProgress progress) onProgress,
  }) async {
    throw const VoiceDownloadException(unavailableMessage);
  }

  @override
  void cancel(VoiceId id) {}

  @override
  Future<void> delete(VoiceId id) async {
    throw const VoiceDownloadException(unavailableMessage);
  }
}
