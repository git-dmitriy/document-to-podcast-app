import 'dart:async';
import 'dart:io';

import 'voice_download_exception.dart';
import 'voice_file_source.dart';

final class HttpVoiceFileSource implements VoiceFileSource {
  @override
  Future<VoiceByteStream> open(Uri url, {int fromByte = 0}) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.getUrl(url);
      request.followRedirects = true;
      request.maxRedirects = 5;
      if (fromByte > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$fromByte-');
      }
      final response = await request.close();
      final total = voiceContentTotal(
        statusCode: response.statusCode,
        contentLength: response.contentLength,
        contentRange: response.headers.value(HttpHeaders.contentRangeHeader),
        fromByte: fromByte,
      );
      final controller = StreamController<List<int>>();
      final subscription = response.listen(
        controller.add,
        onError: controller.addError,
        onDone: () {
          client.close();
          controller.close();
        },
        cancelOnError: true,
      );
      controller.onCancel = () {
        subscription.cancel();
        client.close(force: true);
      };
      return VoiceByteStream(
        statusCode: response.statusCode,
        totalBytes: total,
        bytes: controller.stream,
      );
    } on IOException catch (error, stackTrace) {
      client.close(force: true);
      Error.throwWithStackTrace(
        VoiceDownloadException('Could not download the voice.', cause: error),
        stackTrace,
      );
    } catch (error) {
      client.close(force: true);
      rethrow;
    }
  }
}
