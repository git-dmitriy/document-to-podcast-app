import 'package:document_to_podcast/data/voice_download_exception.dart';
import 'package:document_to_podcast/data/web_model_downloader.dart';
import 'package:document_to_podcast/domain/voice_install.dart';
import 'package:document_to_podcast/domain/voice_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refuses quality downloads in the browser', () async {
    const downloader = WebModelDownloader();

    final installs = await downloader.inspect();

    expect(installs, hasLength(voiceCatalog.length));
    expect(
      installs.every((install) => install.status == VoiceInstallStatus.missing),
      isTrue,
    );
    expect(
      downloader.download(VoiceId.irina, onProgress: (_) {}),
      throwsA(
        isA<VoiceDownloadException>().having(
          (error) => error.message,
          'message',
          WebModelDownloader.unavailableMessage,
        ),
      ),
    );
    downloader.cancel(VoiceId.irina);
    expect(
      downloader.delete(VoiceId.lessac),
      throwsA(isA<VoiceDownloadException>()),
    );
  });
}
