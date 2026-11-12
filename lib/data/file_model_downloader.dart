import 'dart:io';

import '../domain/voice_install.dart';
import '../domain/voice_package.dart';
import 'model_downloader.dart';
import 'voice_download_exception.dart';
import 'voice_file_source.dart';

final class FileModelDownloader implements ModelDownloader {
  FileModelDownloader({
    required this._directory,
    required this._source,
  });

  static const _emitStep = 65536;

  final Directory _directory;
  final VoiceFileSource _source;
  final Map<VoiceId, int> _generation = {};

  @override
  Future<List<VoiceInstall>> inspect() async {
    final installs = <VoiceInstall>[];
    for (final voice in voiceCatalog) {
      var complete = true;
      var partial = false;
      var bytes = 0;
      for (final file in voice.files) {
        final saved = _file(voice, file.name, partial: false);
        if (await saved.exists() && await saved.length() > 0) {
          bytes += await saved.length();
          continue;
        }
        complete = false;
        final incomplete = _file(voice, file.name, partial: true);
        if (await incomplete.exists() && await incomplete.length() > 0) {
          partial = true;
          bytes += await incomplete.length();
        }
      }
      installs.add(
        VoiceInstall(
          id: voice.id,
          status: complete
              ? VoiceInstallStatus.installed
              : partial
              ? VoiceInstallStatus.partial
              : VoiceInstallStatus.missing,
          downloadedBytes: bytes,
        ),
      );
    }
    return installs;
  }

  @override
  Future<void> download(
    VoiceId id, {
    required void Function(VoiceDownloadProgress progress) onProgress,
  }) async {
    final voice = voiceById(id);
    final token = _begin(id);
    final ledger = _Ledger();
    for (final file in voice.files) {
      if (!_current(id, token)) return;
      await _transfer(
        voice: voice,
        file: file,
        token: token,
        ledger: ledger,
        onProgress: onProgress,
      );
    }
  }

  @override
  void cancel(VoiceId id) {
    _generation[id] = (_generation[id] ?? 0) + 1;
  }

  @override
  Future<void> delete(VoiceId id) async {
    cancel(id);
    final folder = Directory('${_directory.path}/${id.name}');
    if (await folder.exists()) {
      await folder.delete(recursive: true);
    }
  }

  int _begin(VoiceId id) {
    final next = (_generation[id] ?? 0) + 1;
    _generation[id] = next;
    return next;
  }

  bool _current(VoiceId id, int token) => _generation[id] == token;

  Future<void> _transfer({
    required VoicePackage voice,
    required VoiceFile file,
    required int token,
    required _Ledger ledger,
    required void Function(VoiceDownloadProgress progress) onProgress,
  }) async {
    final target = _file(voice, file.name, partial: false);
    final partial = _file(voice, file.name, partial: true);
    if (await target.exists() && await target.length() > 0) {
      final length = await target.length();
      ledger.received[file.name] = length;
      ledger.totals[file.name] = length;
      _emit(voice, ledger, onProgress);
      return;
    }

    await partial.parent.create(recursive: true);
    var received = await partial.exists() ? await partial.length() : 0;
    var attempt = 0;
    while (attempt < 2) {
      if (!_current(voice.id, token)) return;
      attempt++;
      try {
        final response = await _source.open(file.url, fromByte: received);
        if (response.statusCode == 416 ||
            (response.statusCode != 200 && response.statusCode != 206)) {
          await response.bytes.drain<void>();
        }
        if (response.statusCode == 416) {
          if (await partial.exists()) await partial.delete();
          received = 0;
          continue;
        }
        if (response.statusCode != 200 && response.statusCode != 206) {
          throw VoiceDownloadException('Could not download ${voice.title}.');
        }
        final append = response.statusCode == 206 && received > 0;
        if (!append) received = 0;
        ledger.received[file.name] = received;
        ledger.totals[file.name] = response.totalBytes;
        final sink = partial.openWrite(
          mode: append ? FileMode.append : FileMode.write,
        );
        var cancelled = false;
        var sinceEmit = 0;
        try {
          await for (final chunk in response.bytes) {
            if (!_current(voice.id, token)) {
              cancelled = true;
              break;
            }
            sink.add(chunk);
            received += chunk.length;
            sinceEmit += chunk.length;
            ledger.received[file.name] = received;
            if (sinceEmit >= _emitStep) {
              sinceEmit = 0;
              _emit(voice, ledger, onProgress);
            }
            if (!_current(voice.id, token)) {
              cancelled = true;
              break;
            }
          }
        } finally {
          await sink.flush();
          await sink.close();
        }
        if (cancelled || !_current(voice.id, token)) return;
        final total = response.totalBytes;
        if (total != null && received < total) {
          throw VoiceDownloadException(
            'The download of ${voice.title} stopped early.',
          );
        }
        if (received == 0) {
          throw VoiceDownloadException('Could not download ${voice.title}.');
        }
        if (await target.exists()) await target.delete();
        await partial.rename(target.path);
        ledger.received[file.name] = received;
        ledger.totals[file.name] = total ?? received;
        _emit(voice, ledger, onProgress);
        return;
      } on VoiceDownloadException {
        rethrow;
      } catch (error, stackTrace) {
        Error.throwWithStackTrace(
          VoiceDownloadException(
            'Could not download ${voice.title}.',
            cause: error,
          ),
          stackTrace,
        );
      }
    }
    throw VoiceDownloadException('Could not download ${voice.title}.');
  }

  void _emit(
    VoicePackage voice,
    _Ledger ledger,
    void Function(VoiceDownloadProgress progress) onProgress,
  ) {
    var received = 0;
    var known = true;
    var total = 0;
    for (final file in voice.files) {
      received += ledger.received[file.name] ?? 0;
      final fileTotal = ledger.totals[file.name];
      if (fileTotal == null) {
        known = false;
      } else {
        total += fileTotal;
      }
    }
    onProgress(
      VoiceDownloadProgress(
        id: voice.id,
        receivedBytes: received,
        totalBytes: known ? total : null,
      ),
    );
  }

  File _file(VoicePackage voice, String name, {required bool partial}) {
    final suffix = partial ? '.partial' : '';
    return File('${_directory.path}/${voice.id.name}/$name$suffix');
  }
}

final class _Ledger {
  final received = <String, int>{};
  final totals = <String, int?>{};
}
