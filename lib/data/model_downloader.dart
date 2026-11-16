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

  /// Absolute paths of a fully installed voice, or null when a file is missing.
  Future<InstalledVoiceModel?> installedModel(VoiceId id);
}

final class InstalledVoiceModel {
  const InstalledVoiceModel({
    required this.modelPath,
    required this.configPath,
  });

  final String modelPath;
  final String configPath;
}
