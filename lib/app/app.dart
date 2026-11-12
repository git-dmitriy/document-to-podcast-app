import 'dart:async';

import 'package:flutter/material.dart';

import '../data/document_store.dart';
import '../data/settings_repository.dart';
import '../data/system_tts_engine.dart';
import '../domain/playback_settings.dart';
import '../domain/tts_engine.dart';
import '../ui/library/library_controller.dart';
import '../ui/library/library_screen.dart';
import '../ui/reader/playback_controller.dart';
import '../ui/settings/settings_controller.dart';
import 'app_spacing.dart';
import 'app_surface.dart';
import 'theme.dart';

class DocumentToPodcastApp extends StatefulWidget {
  const DocumentToPodcastApp({
    required this.store,
    required this.settingsRepository,
    required this.initialSettings,
    this.speech,
    this.surface,
    super.key,
  });

  final DocumentStore store;
  final SettingsRepository settingsRepository;
  final PlaybackSettings initialSettings;
  final TtsEngine? speech;
  final AppSurface? surface;

  @override
  State<DocumentToPodcastApp> createState() => _DocumentToPodcastAppState();
}

class _DocumentToPodcastAppState extends State<DocumentToPodcastApp> {
  late final LibraryController _controller = LibraryController(
    store: widget.store,
  );
  late final SettingsController _settings = SettingsController(
    repository: widget.settingsRepository,
    initial: widget.initialSettings,
  );
  late final PlaybackController _playback = PlaybackController(
    engine: widget.speech ?? SystemTtsEngine(),
    fallbackLanguage: widget.initialSettings.fallbackLanguage,
    rate: widget.initialSettings.rate,
  );
  late final AppSurface _surface = widget.surface ?? currentAppSurface();

  @override
  void initState() {
    super.initState();
    _settings.addListener(_applySettings);
  }

  @override
  void dispose() {
    _settings.removeListener(_applySettings);
    _playback.dispose();
    _settings.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _applySettings() {
    final settings = _settings.settings;
    _playback.setFallbackLanguage(settings.fallbackLanguage);
    unawaited(_playback.setRate(settings.rate));
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
      home: LibraryScreen(
        controller: _controller,
        playback: _playback,
        settings: _settings,
        surface: _surface,
      ),
    );
  }
}
