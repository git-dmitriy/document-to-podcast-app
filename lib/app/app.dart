import 'dart:async';

import 'package:flutter/material.dart';

import '../data/audio_cache.dart';
import '../data/document_store.dart';
import '../data/memory_quality_prompt_store.dart';
import '../data/model_downloader.dart';
import '../data/playback_position_store.dart';
import '../data/playback_wake_lock.dart';
import '../data/quality_prompt_store.dart';
import '../data/settings_repository.dart';
import '../data/tts_engine_factory.dart';
import '../domain/playback_settings.dart';
import '../domain/tts_engine.dart';
import '../ui/library/library_controller.dart';
import '../ui/library/library_screen.dart';
import '../ui/library/quality_prompt_controller.dart';
import '../ui/reader/playback_controller.dart';
import '../ui/settings/settings_controller.dart';
import '../ui/settings/voice_library_controller.dart';
import 'app_spacing.dart';
import 'app_surface.dart';
import 'theme.dart';

class DocumentToPodcastApp extends StatefulWidget {
  const DocumentToPodcastApp({
    required this.store,
    required this.settingsRepository,
    required this.initialSettings,
    required this.voices,
    this.qualityPrompt,
    this.positions,
    this.wakeLock,
    this.audioCache,
    this.speech,
    this.engines,
    this.surface,
    super.key,
  });

  final DocumentStore store;
  final SettingsRepository settingsRepository;
  final PlaybackSettings initialSettings;
  final ModelDownloader voices;
  final QualityPromptStore? qualityPrompt;
  final PlaybackPositionStore? positions;
  final PlaybackWakeLock? wakeLock;
  final AudioCache? audioCache;
  final TtsEngine? speech;
  final TtsEngineFactory? engines;
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
  late final VoiceLibraryController _voices = VoiceLibraryController(
    downloader: widget.voices,
  );
  late final QualityPromptController _qualityPrompt = QualityPromptController(
    store: widget.qualityPrompt ?? MemoryQualityPromptStore(),
  );
  late final AppSurface _surface = widget.surface ?? currentAppSurface();
  late final TtsEngineFactory _engines =
      widget.engines ??
      AppTtsEngineFactory(voices: widget.voices, cache: widget.audioCache);
  late SpeechEngine _appliedEngine = _surface == AppSurface.web
      ? SpeechEngine.system
      : widget.initialSettings.engine;
  late final PlaybackController _playback = PlaybackController(
    engine:
        widget.speech ??
        _engines.create(
          _surface == AppSurface.web
              ? SpeechEngine.system
              : widget.initialSettings.engine,
        ),
    fallbackLanguage: widget.initialSettings.fallbackLanguage,
    rate: widget.initialSettings.rate,
    positions: widget.positions,
    wakeLock: widget.wakeLock,
  );

  @override
  void initState() {
    super.initState();
    _settings.addListener(_applySettings);
    unawaited(_voices.load());
    unawaited(_qualityPrompt.load());
  }

  @override
  void dispose() {
    _settings.removeListener(_applySettings);
    _playback.dispose();
    _voices.dispose();
    _qualityPrompt.dispose();
    _settings.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _applySettings() {
    final settings = _settings.settings;
    _playback.setFallbackLanguage(settings.fallbackLanguage);
    unawaited(_playback.setRate(settings.rate));
    if (widget.speech != null || _surface == AppSurface.web) return;
    if (settings.engine == _appliedEngine) return;
    _appliedEngine = settings.engine;
    unawaited(_playback.useEngine(_engines.create(settings.engine)));
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
        voices: _voices,
        qualityPrompt: _qualityPrompt,
        surface: _surface,
      ),
    );
  }
}
