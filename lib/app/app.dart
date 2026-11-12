import 'package:flutter/material.dart';

import '../data/document_store.dart';
import '../ui/library/library_controller.dart';
import '../ui/library/library_screen.dart';
import 'app_spacing.dart';
import 'theme.dart';

class DocumentToPodcastApp extends StatefulWidget {
  const DocumentToPodcastApp({required this.store, super.key});

  final DocumentStore store;

  @override
  State<DocumentToPodcastApp> createState() => _DocumentToPodcastAppState();
}

class _DocumentToPodcastAppState extends State<DocumentToPodcastApp> {
  late final LibraryController _controller = LibraryController(
    store: widget.store,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document to Podcast',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final theme = Theme.of(context);
        final spacing = AppSpacing.forWidth(MediaQuery.sizeOf(context).width);
        return Theme(
          data: theme.copyWith(
            extensions: [...theme.extensions.values, spacing],
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: LibraryScreen(controller: _controller),
    );
  }
}
