import 'package:flutter/foundation.dart';

import '../../data/model_downloader.dart';
import '../../data/voice_download_exception.dart';
import '../../domain/voice_install.dart';
import '../../domain/voice_package.dart';

final class VoiceLibraryController extends ChangeNotifier {
  VoiceLibraryController({required this._downloader});

  final ModelDownloader _downloader;
  var _loading = true;
  var _disposed = false;
  Map<VoiceId, VoiceInstall> _installs = const {};
  Map<VoiceId, VoiceDownloadProgress> _progress = const {};
  Map<VoiceId, String> _errors = const {};
  Set<VoiceId> _downloading = const {};

  bool get isLoading => _loading;

  VoiceInstallStatus statusOf(VoiceId id) {
    if (_downloading.contains(id)) return VoiceInstallStatus.downloading;
    return _installs[id]?.status ?? VoiceInstallStatus.missing;
  }

  VoiceDownloadProgress? progressOf(VoiceId id) => _progress[id];

  String? errorOf(VoiceId id) => _errors[id];

  Future<void> load() async {
    try {
      final installs = await _downloader.inspect();
      if (_disposed) return;
      _installs = {for (final install in installs) install.id: install};
      _loading = false;
      _notify();
    } on VoiceDownloadException catch (error) {
      if (_disposed) return;
      _loading = false;
      _errors = {for (final voice in voiceCatalog) voice.id: error.message};
      _notify();
    }
  }

  Future<void> download(VoiceId id) async {
    if (_disposed || _downloading.contains(id)) return;
    _downloading = {..._downloading, id};
    _errors = {..._errors}..remove(id);
    _notify();
    try {
      await _downloader.download(
        id,
        onProgress: (progress) {
          if (_disposed) return;
          _progress = {..._progress, id: progress};
          _notify();
        },
      );
    } on VoiceDownloadException catch (error) {
      if (_disposed) return;
      _errors = {..._errors, id: error.message};
    } finally {
      _downloading = {..._downloading}..remove(id);
      _progress = {..._progress}..remove(id);
      if (!_disposed) await load();
    }
  }

  Future<void> remove(VoiceId id) async {
    if (_disposed) return;
    _downloader.cancel(id);
    try {
      await _downloader.delete(id);
    } on VoiceDownloadException catch (error) {
      if (_disposed) return;
      _errors = {..._errors, id: error.message};
      _notify();
      return;
    }
    await load();
  }

  void cancel(VoiceId id) {
    _downloader.cancel(id);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final voice in voiceCatalog) {
      _downloader.cancel(voice.id);
    }
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
