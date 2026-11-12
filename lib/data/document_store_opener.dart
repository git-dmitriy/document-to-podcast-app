import 'document_store.dart';
import 'document_store_opener_io.dart'
    if (dart.library.html) 'document_store_opener_web.dart'
    as opener;

Future<DocumentStore> openDocumentStore() => opener.openDocumentStore();
