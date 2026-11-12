import 'package:flutter_test/flutter_test.dart';

import 'package:document_to_podcast/app/app.dart';

void main() {
  testWidgets('shows scaffold home shell', (tester) async {
    await tester.pumpWidget(const DocumentToPodcastApp());

    expect(find.text('Document to Podcast'), findsOneWidget);
    expect(find.textContaining('Offline Markdown narration'), findsOneWidget);
  });
}
