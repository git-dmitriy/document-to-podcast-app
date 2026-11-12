import 'package:document_to_podcast/app/window_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps width to window classes', () {
    expect(WindowSize.fromWidth(599), WindowSize.compact);
    expect(WindowSize.fromWidth(600), WindowSize.medium);
    expect(WindowSize.fromWidth(839).showsTwoPanes, isFalse);
    expect(WindowSize.fromWidth(840).showsTwoPanes, isTrue);
    expect(WindowSize.fromWidth(1600), WindowSize.extraLarge);
  });
}
