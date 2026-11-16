import 'package:document_to_podcast/data/model_downloader.dart';
import 'package:document_to_podcast/domain/voice_install.dart';
import 'package:document_to_podcast/domain/voice_package.dart';

final class MemoryModelDownloader implements ModelDownloader {
  final installed = <VoiceId>{};
  final downloads = <VoiceId>[];
  Object? failure;

  @override
  Future<List<VoiceInstall>> inspect() async {
    return [
      for (final voice in voiceCatalog)
        VoiceInstall(
          id: voice.id,
          status: installed.contains(voice.id)
              ? VoiceInstallStatus.installed
              : VoiceInstallStatus.missing,
        ),
    ];
  }

  @override
  Future<void> download(
    VoiceId id, {
    required void Function(VoiceDownloadProgress progress) onProgress,
  }) async {
    downloads.add(id);
    final failure = this.failure;
    if (failure != null) throw failure;
    onProgress(VoiceDownloadProgress(id: id, receivedBytes: 1, totalBytes: 2));
    onProgress(VoiceDownloadProgress(id: id, receivedBytes: 2, totalBytes: 2));
    installed.add(id);
  }

  @override
  void cancel(VoiceId id) {}

  @override
  Future<void> delete(VoiceId id) async {
    installed.remove(id);
    models.remove(id);
  }

  final models = <VoiceId, InstalledVoiceModel>{};

  @override
  Future<InstalledVoiceModel?> installedModel(VoiceId id) async => models[id];
}
