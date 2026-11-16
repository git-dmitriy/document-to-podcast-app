import 'voice_package.dart';

enum VoiceInstallStatus { missing, partial, installed, downloading }

final class VoiceInstall {
  const VoiceInstall({
    required this.id,
    required this.status,
    this.downloadedBytes = 0,
  });

  final VoiceId id;
  final VoiceInstallStatus status;
  final int downloadedBytes;
}

final class VoiceDownloadProgress {
  const VoiceDownloadProgress({
    required this.id,
    required this.receivedBytes,
    required this.totalBytes,
  });

  final VoiceId id;
  final int receivedBytes;
  final int? totalBytes;

  double? get fraction {
    final total = totalBytes;
    if (total == null || total <= 0) return null;
    final value = receivedBytes / total;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}
