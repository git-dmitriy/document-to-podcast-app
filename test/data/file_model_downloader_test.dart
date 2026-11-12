import 'dart:async';
import 'dart:io';

import 'package:document_to_podcast/data/file_model_downloader.dart';
import 'package:document_to_podcast/data/voice_download_exception.dart';
import 'package:document_to_podcast/data/voice_file_source.dart';
import 'package:document_to_podcast/domain/voice_install.dart';
import 'package:document_to_podcast/domain/voice_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('voices-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('downloads both files and reports progress', () async {
    final voice = voiceById(VoiceId.irina);
    final progress = <VoiceDownloadProgress>[];
    final downloader = FileModelDownloader(
      directory: root,
      source: ScriptedVoiceFileSource((url, fromByte) async {
        if (url.path.endsWith('.json')) {
          return payload(const [8, 9], totalBytes: 2);
        }
        return payload(List<int>.filled(65537, 7), totalBytes: 65537);
      }),
    );

    await downloader.download(voice.id, onProgress: progress.add);

    expect(progress.length, greaterThanOrEqualTo(3));
    expect(progress.last.fraction, 1);
    expect(
      progress.take(progress.length - 1).every((item) => item.fraction == null),
      isTrue,
    );
    expect(
      (await downloader.inspect()).byId(voice.id).status,
      VoiceInstallStatus.installed,
    );
    expect(
      await _stored(root, voice.files.first).readAsBytes(),
      List<int>.filled(65537, 7),
    );
  });

  test('skips files that are already installed', () async {
    final voice = voiceById(VoiceId.lessac);
    final source = ScriptedVoiceFileSource((url, fromByte) async {
      throw StateError('open');
    });
    await _write(root, voice, const [1]);
    final downloader = FileModelDownloader(directory: root, source: source);

    await downloader.download(voice.id, onProgress: (_) {});

    expect(source.calls, isEmpty);
    expect(
      (await downloader.inspect()).byId(voice.id).status,
      VoiceInstallStatus.installed,
    );
  });

  test('resumes a partial file with a ranged response', () async {
    final voice = voiceById(VoiceId.irina);
    final model = voice.files.first;
    await _writePartial(root, voice, model, const [1, 2]);
    final source = ScriptedVoiceFileSource((url, fromByte) async {
      if (url.path.endsWith('.json')) {
        return payload(const [9], totalBytes: 1);
      }
      expect(fromByte, 2);
      return payload(const [3, 4], statusCode: 206, totalBytes: 4);
    });
    final downloader = FileModelDownloader(directory: root, source: source);

    expect(
      (await downloader.inspect()).byId(voice.id).status,
      VoiceInstallStatus.partial,
    );
    await downloader.download(voice.id, onProgress: (_) {});

    expect(await _stored(root, model).readAsBytes(), const [1, 2, 3, 4]);
    expect(await _stored(root, model, partial: true).exists(), isFalse);
  });

  test('a full response replaces a partial file', () async {
    final voice = voiceById(VoiceId.irina);
    final model = voice.files.first;
    await _writePartial(root, voice, model, const [9, 9, 9, 9]);
    final downloader = FileModelDownloader(
      directory: root,
      source: ScriptedVoiceFileSource((url, fromByte) async {
        if (url.path.endsWith('.json')) {
          return payload(const [1], totalBytes: 1);
        }
        expect(fromByte, 4);
        return payload(const [1, 2], statusCode: 200, totalBytes: 2);
      }),
    );

    await downloader.download(voice.id, onProgress: (_) {});

    expect(await _stored(root, model).readAsBytes(), const [1, 2]);
  });

  test(
    'keeps the partial file when the body is shorter than the total',
    () async {
      final voice = voiceById(VoiceId.irina);
      final model = voice.files.first;
      final source = ScriptedVoiceFileSource((url, fromByte) async {
        return payload(const [1, 2, 3], totalBytes: 10);
      });
      final downloader = FileModelDownloader(directory: root, source: source);

      await expectLater(
        downloader.download(voice.id, onProgress: (_) {}),
        throwsA(
          isA<VoiceDownloadException>().having(
            (error) => error.message,
            'message',
            'The download of Irina stopped early.',
          ),
        ),
      );

      expect(source.calls, hasLength(1));
      expect(await _stored(root, model, partial: true).readAsBytes(), const [
        1,
        2,
        3,
      ]);
      expect(await _stored(root, model).exists(), isFalse);
    },
  );

  test('retries from the start after a range is not satisfiable', () async {
    final voice = voiceById(VoiceId.lessac);
    final model = voice.files.first;
    await _writePartial(root, voice, model, const [4, 5]);
    var modelCalls = 0;
    final downloader = FileModelDownloader(
      directory: root,
      source: ScriptedVoiceFileSource((url, fromByte) async {
        if (url.path.endsWith('.json')) {
          return payload(const [1], totalBytes: 1);
        }
        modelCalls++;
        if (modelCalls == 1) {
          expect(fromByte, 2);
          return payload(const [], statusCode: 416);
        }
        expect(fromByte, 0);
        return payload(const [7], totalBytes: 1);
      }),
    );

    await downloader.download(voice.id, onProgress: (_) {});

    expect(modelCalls, 2);
    expect(await _stored(root, model, folder: voice.id).readAsBytes(), const [
      7,
    ]);
  });

  test('cancel leaves the partial file uninstalled', () async {
    final voice = voiceById(VoiceId.irina);
    final model = voice.files.first;
    final body = StreamController<List<int>>();
    final downloader = FileModelDownloader(
      directory: root,
      source: ScriptedVoiceFileSource((url, fromByte) async {
        return VoiceByteStream(
          statusCode: 200,
          totalBytes: 6,
          bytes: body.stream,
        );
      }),
    );

    final pending = downloader.download(voice.id, onProgress: (_) {});
    await pumpEventQueue();
    body.add(const [1, 2, 3, 4]);
    await pumpEventQueue();
    downloader.cancel(voice.id);
    body.add(const [5, 6]);
    await body.close();
    await pending;

    expect(await _stored(root, model).exists(), isFalse);
    expect(await _stored(root, model, partial: true).readAsBytes(), const [
      1,
      2,
      3,
      4,
    ]);
  });

  test('names the voice when the source fails', () async {
    final downloader = FileModelDownloader(
      directory: root,
      source: ScriptedVoiceFileSource((url, fromByte) async {
        throw const FileSystemException('disk');
      }),
    );

    await expectLater(
      downloader.download(VoiceId.lessac, onProgress: (_) {}),
      throwsA(
        isA<VoiceDownloadException>().having(
          (error) => error.message,
          'message',
          'Could not download Lessac.',
        ),
      ),
    );
  });
}

VoiceByteStream payload(
  List<int> bytes, {
  int statusCode = 200,
  int? totalBytes,
}) {
  return VoiceByteStream(
    statusCode: statusCode,
    totalBytes: totalBytes,
    bytes: Stream<List<int>>.value(bytes),
  );
}

final class ScriptedVoiceFileSource implements VoiceFileSource {
  ScriptedVoiceFileSource(this._open);

  final Future<VoiceByteStream> Function(Uri url, int fromByte) _open;
  final calls = <(Uri, int)>[];

  @override
  Future<VoiceByteStream> open(Uri url, {int fromByte = 0}) {
    calls.add((url, fromByte));
    return _open(url, fromByte);
  }
}

extension on List<VoiceInstall> {
  VoiceInstall byId(VoiceId id) {
    return firstWhere((install) => install.id == id);
  }
}

Future<void> _write(Directory root, VoicePackage voice, List<int> bytes) async {
  for (final file in voice.files) {
    final target = _stored(root, file, folder: voice.id);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes);
  }
}

Future<void> _writePartial(
  Directory root,
  VoicePackage voice,
  VoiceFile file,
  List<int> bytes,
) async {
  final target = _stored(root, file, folder: voice.id, partial: true);
  await target.parent.create(recursive: true);
  await target.writeAsBytes(bytes);
}

File _stored(
  Directory root,
  VoiceFile file, {
  VoiceId folder = VoiceId.irina,
  bool partial = false,
}) {
  final suffix = partial ? '.partial' : '';
  return File('${root.path}/${folder.name}/${file.name}$suffix');
}
