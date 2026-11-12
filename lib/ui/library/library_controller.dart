import 'package:flutter/foundation.dart';

import '../../data/async_lock.dart';
import '../../data/document_store.dart';
import '../../data/document_store_exception.dart';
import '../../domain/document.dart';

final class LibraryState {
  const LibraryState({
    this.isLoading = false,
    this.documents = const [],
    this.selectedId,
    this.errorMessage,
  });

  final bool isLoading;
  final List<Document> documents;
  final String? selectedId;
  final String? errorMessage;

  Document? documentById(String id) {
    for (final document in documents) {
      if (document.id == id) return document;
    }
    return null;
  }
}

final class LibraryController extends ChangeNotifier {
  LibraryController({required this._store});

  final DocumentStore _store;
  final AsyncLock _lock = AsyncLock();
  LibraryState _state = const LibraryState();
  bool _disposed = false;

  LibraryState get state => _state;

  Future<void> load() {
    return _run(() async {
      _publish(
        LibraryState(
          isLoading: true,
          documents: _state.documents,
          selectedId: _state.selectedId,
        ),
      );
      try {
        final documents = await _store.loadAll();
        _publish(
          LibraryState(
            documents: documents,
            selectedId: _selectedIfPresent(_state.selectedId, documents),
          ),
        );
      } on DocumentStoreException catch (error) {
        _publish(
          LibraryState(
            documents: _state.documents,
            selectedId: _state.selectedId,
            errorMessage: error.message,
          ),
        );
      }
    });
  }

  Future<Document> importMarkdown({
    required String title,
    required String markdown,
    String? sourceName,
  }) {
    return _run(() async {
      final document = await _store.create(
        title: title,
        markdown: markdown,
        sourceName: sourceName,
      );
      _publish(
        LibraryState(
          documents: sortDocuments([..._state.documents, document]),
          selectedId: _state.selectedId,
        ),
      );
      return document;
    });
  }

  Future<void> delete(String id) {
    return _run(() async {
      await _store.delete(id);
      final documents = [
        for (final document in _state.documents)
          if (document.id != id) document,
      ];
      _publish(
        LibraryState(
          documents: sortDocuments(documents),
          selectedId: _state.selectedId == id ? null : _state.selectedId,
        ),
      );
    });
  }

  void select(String? id) {
    if (_disposed || _state.selectedId == id) return;
    _publish(
      LibraryState(
        documents: _state.documents,
        selectedId: id,
        errorMessage: _state.errorMessage,
      ),
    );
  }

  Future<T> _run<T>(Future<T> Function() action) {
    return _lock.run(() {
      if (_disposed) {
        throw const DocumentStoreException('The library is closed.');
      }
      return action();
    });
  }

  void _publish(LibraryState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

String? _selectedIfPresent(String? selectedId, List<Document> documents) {
  if (selectedId == null) return null;
  for (final document in documents) {
    if (document.id == selectedId) return selectedId;
  }
  return null;
}
