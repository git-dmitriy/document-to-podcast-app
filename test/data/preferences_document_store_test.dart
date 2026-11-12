import 'package:document_to_podcast/data/document_store_exception.dart';
import 'package:document_to_podcast/data/preferences_document_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stores documents in preferences', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = PreferencesDocumentStore(
      preferences,
      clock: () => DateTime.utc(2026, 3, 1),
      newId: () => 'doc-1',
    );

    final created = await store.create(
      title: '',
      markdown: '# Hello\n\nBody',
      sourceName: 'ignored.md',
    );
    final again = PreferencesDocumentStore(preferences);

    expect(await again.loadAll(), [created]);
    await again.delete(created.id);
    expect(await again.loadAll(), isEmpty);
    await again.delete(created.id);
  });

  test('rejects empty markdown', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = PreferencesDocumentStore(preferences);

    expect(
      () => store.create(title: '', markdown: ' '),
      throwsA(isA<DocumentStoreException>()),
    );
    expect(preferences.getString(PreferencesDocumentStore.indexKey), isNull);
  });
}
