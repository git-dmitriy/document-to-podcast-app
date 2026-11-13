import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'audio_cache.dart';
import 'file_audio_cache.dart';

Future<AudioCache> openAudioCache() async {
  final support = await getApplicationSupportDirectory();
  return FileAudioCache(Directory('${support.path}/audio-cache'));
}
