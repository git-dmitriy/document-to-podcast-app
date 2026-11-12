import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';
import '../../app/app_surface.dart';
import '../../domain/app_language.dart';
import '../reader/playback_controller.dart';
import '../reader/playback_speed_slider.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.playback,
    required this.surface,
    super.key,
  });

  final SettingsController settings;
  final PlaybackController playback;
  final AppSurface surface;

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
              listenable: Listenable.merge([settings, playback]),
              builder: (context, _) {
                final theme = Theme.of(context);
                final errorMessage = settings.errorMessage;
                final language = settings.settings.fallbackLanguage;
                return ListView(
                  padding: EdgeInsets.all(spacing.pagePadding),
                  children: [
                    Text('Speech', style: theme.textTheme.titleMedium),
                    SizedBox(height: spacing.sectionGap),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Engine'),
                      subtitle: Text(
                        surface == AppSurface.web
                            ? 'System speech is the only engine in the browser.'
                            : 'System',
                      ),
                    ),
                    Text('Speed', style: theme.textTheme.titleSmall),
                    PlaybackSpeedSlider(playback: playback, settings: settings),
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
