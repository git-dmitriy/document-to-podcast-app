import 'package:document_to_podcast/data/playback_position_codec.dart';
import 'package:document_to_podcast/data/preferences_playback_position_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('drops unreadable position records', () {
    expect(decodePlaybackPositions(null), isEmpty);
    expect(decodePlaybackPositions('{'), isEmpty);
    expect(decodePlaybackPositions('{"version":2}'), isEmpty);
    expect(
      decodePlaybackPositions(
        '{"version":1,"positions":{"ok":1,"bad id":2,"neg":-1,"x":"1"}}',
      ),
      {'ok': 1},
    );
  });

  test('saves and clears a document position', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = PreferencesPlaybackPositionStore(preferences);

    expect(await store.read('doc-1'), isNull);
    await store.save('doc-1', 3);
    await store.save('doc-2', 1);

    final again = PreferencesPlaybackPositionStore(preferences);
    expect(await again.read('doc-1'), 3);
    await again.clear('doc-1');
    expect(await again.read('doc-1'), isNull);
    expect(await again.read('doc-2'), 1);
  });
}
