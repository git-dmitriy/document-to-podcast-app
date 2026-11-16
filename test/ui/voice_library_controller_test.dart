import 'dart:async';

import 'package:document_to_podcast/data/model_downloader.dart';
import 'package:document_to_podcast/data/voice_download_exception.dart';
import 'package:document_to_podcast/domain/voice_install.dart';
import 'package:document_to_podcast/domain/voice_package.dart';
import 'package:document_to_podcast/ui/settings/voice_library_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/memory_model_downloader.dart';

void main() {
  test('reports progress and then an installed voice', () async {
    final downloader = _GateDownloader();
    final controller = VoiceLibraryController(downloader: downloader);
    addTearDown(controller.dispose);
    await controller.load();

    final pending = controller.download(VoiceId.irina);
    await downloader.started.future;

    expect(controller.statusOf(VoiceId.irina), VoiceInstallStatus.downloading);
    expect(controller.progressOf(VoiceId.irina)?.fraction, 0.5);

    downloader.release.complete();
    await pending;

    expect(controller.statusOf(VoiceId.irina), VoiceInstallStatus.installed);
    expect(controller.progressOf(VoiceId.irina), isNull);
    expect(controller.errorOf(VoiceId.irina), isNull);
  });

  test('keeps the voice missing when the download fails', () async {
    final downloader = MemoryModelDownloader()
      ..failure = const VoiceDownloadException('Could not download Irina.');
    final controller = VoiceLibraryController(downloader: downloader);
    addTearDown(controller.dispose);

    await controller.download(VoiceId.irina);

    expect(controller.statusOf(VoiceId.irina), VoiceInstallStatus.missing);
    expect(controller.errorOf(VoiceId.irina), 'Could not download Irina.');
  });

  test('cancel stops an in-flight download', () async {
    final downloader = _GateDownloader();
    final controller = VoiceLibraryController(downloader: downloader);
    addTearDown(controller.dispose);
    await controller.load();

    final pending = controller.download(VoiceId.lessac);
    await downloader.started.future;
    controller.cancel(VoiceId.lessac);
    downloader.release.complete();
    await pending;

    expect(downloader.cancelled, isTrue);
    expect(controller.statusOf(VoiceId.lessac), VoiceInstallStatus.missing);
  });

  test('removes an installed voice', () async {
    final downloader = MemoryModelDownloader();
    final controller = VoiceLibraryController(downloader: downloader);
    addTearDown(controller.dispose);

    await controller.download(VoiceId.irina);
    await controller.remove(VoiceId.irina);

    expect(controller.statusOf(VoiceId.irina), VoiceInstallStatus.missing);
  });

  test('does not notify after dispose', () async {
    final downloader = _GateDownloader();
    final controller = VoiceLibraryController(downloader: downloader);
    await controller.load();

    final pending = controller.download(VoiceId.irina);
    await downloader.started.future;
    controller.dispose();
    downloader.release.complete();

    await pending;
    expect(downloader.cancelled, isTrue);
  });
}

final class _GateDownloader implements ModelDownloader {
  final started = Completer<void>();
  final release = Completer<void>();
  final installed = <VoiceId>{};
  var cancelled = false;

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
    onProgress(VoiceDownloadProgress(id: id, receivedBytes: 1, totalBytes: 2));
    if (!started.isCompleted) started.complete();
    await release.future;
    if (cancelled) return;
    installed.add(id);
  }

  @override
  void cancel(VoiceId id) {
    cancelled = true;
  }

  @override
  Future<void> delete(VoiceId id) async {
    installed.remove(id);
  }

  @override
  Future<InstalledVoiceModel?> installedModel(VoiceId id) async => null;
}
