import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'file_model_downloader.dart';
import 'http_voice_file_source.dart';
import 'model_downloader.dart';

Future<ModelDownloader> openModelDownloader() async {
  final support = await getApplicationSupportDirectory();
  return FileModelDownloader(
    directory: Directory('${support.path}/voices'),
    source: HttpVoiceFileSource(),
  );
}
