import 'model_downloader.dart';
import 'web_model_downloader.dart';

Future<ModelDownloader> openModelDownloader() async {
  return const WebModelDownloader();
}
