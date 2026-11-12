import 'package:flutter/material.dart';

import 'theme.dart';
import '../ui/home/home_shell.dart';

class DocumentToPodcastApp extends StatelessWidget {
  const DocumentToPodcastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document to Podcast',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
