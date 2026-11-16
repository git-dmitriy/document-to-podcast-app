import 'model_downloader.dart';
import 'model_downloader_opener_io.dart'
    if (dart.library.html) 'model_downloader_opener_web.dart'
    as opener;

Future<ModelDownloader> openModelDownloader() => opener.openModelDownloader();
