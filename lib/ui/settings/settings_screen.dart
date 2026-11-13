import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';
import '../../app/app_surface.dart';
import '../../domain/app_language.dart';
import '../../domain/playback_settings.dart';
import '../reader/playback_controller.dart';
import '../reader/playback_speed_slider.dart';
import 'quality_voices_section.dart';
import 'settings_controller.dart';
import 'voice_library_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.playback,
    required this.voices,
    required this.surface,
    super.key,
  });

  final SettingsController settings;
  final PlaybackController playback;
  final VoiceLibraryController voices;
  final AppSurface surface;

  static const systemEngineKey = Key('engine-system');
  static const qualityEngineKey = Key('engine-quality');

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: spacing.readingMaxWidth),
            child: ListenableBuilder(
              listenable: Listenable.merge([settings, playback, voices]),
              builder: (context, _) {
                final theme = Theme.of(context);
                final errorMessage = settings.errorMessage;
                final language = settings.settings.fallbackLanguage;
                final web = surface == AppSurface.web;
                final engine = web
                    ? SpeechEngine.system
                    : settings.settings.engine;
                return ListView(
                  padding: EdgeInsets.all(spacing.pagePadding),
                  children: [
                    Text('Speech', style: theme.textTheme.titleMedium),
                    SizedBox(height: spacing.sectionGap),
                    Text('Engine', style: theme.textTheme.titleSmall),
                    RadioGroup<SpeechEngine>(
                      groupValue: engine,
                      onChanged: (value) {
                        if (value == null || web) return;
                        unawaited(settings.setEngine(value));
                      },
                      child: Column(
                        children: [
                          const RadioListTile<SpeechEngine>(
                            key: SettingsScreen.systemEngineKey,
                            contentPadding: EdgeInsets.zero,
                            title: Text('System'),
                            value: SpeechEngine.system,
                          ),
                          RadioListTile<SpeechEngine>(
                            key: SettingsScreen.qualityEngineKey,
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Quality'),
                            subtitle: Text(
                              web
                                  ? 'System speech is the only engine in the browser.'
                                  : 'Missing voices use system speech.',
                            ),
                            value: SpeechEngine.quality,
                            enabled: !web,
                          ),
                        ],
                      ),
                    ),
                    Text('Speed', style: theme.textTheme.titleSmall),
                    PlaybackSpeedSlider(playback: playback, settings: settings),
                    if (!web && engine == SpeechEngine.quality)
                      Text(
                        "Quality speech uses the voice's natural pace.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    SizedBox(height: spacing.sectionGap),
                    Text('Default language', style: theme.textTheme.titleSmall),
                    SizedBox(height: spacing.sectionGap / 2),
                    Text(
                      'Used when a passage has no letters to detect a language.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    RadioGroup<AppLanguage>(
                      groupValue: language,
                      onChanged: (value) {
                        if (value == null) return;
                        unawaited(settings.setFallbackLanguage(value));
                      },
                      child: const Column(
                        children: [
                          RadioListTile<AppLanguage>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('English'),
                            value: AppLanguage.en,
                          ),
                          RadioListTile<AppLanguage>(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Russian'),
                            value: AppLanguage.ru,
                          ),
                        ],
                      ),
                    ),
                    if (errorMessage != null) ...[
                      SizedBox(height: spacing.sectionGap),
                      Text(
                        errorMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                    SizedBox(height: spacing.sectionGap),
                    QualityVoicesSection(voices: voices, surface: surface),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
