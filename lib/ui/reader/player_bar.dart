import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';
import '../../domain/document.dart';
import '../settings/settings_controller.dart';
import 'playback_controller.dart';
import 'playback_speed_slider.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({
    required this.playback,
    required this.settings,
    required this.document,
    super.key,
  });

  final PlaybackController playback;
  final SettingsController settings;
  final Document document;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([playback, settings]),
      builder: (context, _) {
        final theme = Theme.of(context);
        final spacing = AppSpacing.of(context);
        final errorMessage = playback.errorMessage ?? settings.errorMessage;
        final playing = playback.status == PlaybackStatus.playing;
        final paused = playback.status == PlaybackStatus.paused;
        final engine = settings.settings.engine;
        final language =
            playback.currentSegment?.language ??
            settings.settings.fallbackLanguage;
        return Semantics(
          container: true,
          label: 'Playback controls',
          child: Material(
            elevation: playing || paused ? 6 : 2,
            color: theme.colorScheme.surfaceContainerHigh,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.18),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  spacing.sectionGap,
                  spacing.sectionGap * 0.75,
                  spacing.sectionGap,
                  spacing.sectionGap / 2,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: spacing.sectionGap / 2,
                        ),
                        child: Text(
                          errorMessage,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: spacing.sectionGap / 2,
                      runSpacing: spacing.sectionGap / 2,
                      children: [
                        _StatusChip(
                          icon: Icons.graphic_eq,
                          label: engine.label,
                          semanticsLabel: 'Speech engine ${engine.label}',
                        ),
                        _StatusChip(
                          icon: Icons.translate,
                          label: language.label,
                          semanticsLabel: 'Passage language ${language.label}',
                        ),
                        if (playing || paused)
                          _StatusChip(
                            icon: playing
                                ? Icons.play_circle_outline
                                : Icons.pause_circle_outline,
                            label: playing ? 'Playing' : 'Paused',
                            semanticsLabel: playing
                                ? 'Playback is playing'
                                : 'Playback is paused',
                          ),
                      ],
                    ),
                    SizedBox(height: spacing.sectionGap / 2),
                    Row(
                      children: [
                        IconButton(
                          tooltip: playing ? 'Pause' : 'Play',
                          onPressed: () => unawaited(_toggle()),
                          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                        ),
                        IconButton(
                          tooltip: 'Stop',
                          onPressed: playback.status == PlaybackStatus.idle
                              ? null
                              : () => unawaited(_stop()),
                          icon: const Icon(Icons.stop),
                        ),
                        IconButton(
                          tooltip: 'Previous paragraph',
                          onPressed: playback.canSkipBackward
                              ? () => unawaited(_skip(-1))
                              : null,
                          icon: const Icon(Icons.skip_previous),
                        ),
                        IconButton(
                          tooltip: 'Next paragraph',
                          onPressed: playback.canSkipForward
                              ? () => unawaited(_skip(1))
                              : null,
                          icon: const Icon(Icons.skip_next),
                        ),
                        Text('Speed', style: theme.textTheme.labelLarge),
                        Expanded(
                          child: PlaybackSpeedSlider(
                            playback: playback,
                            settings: settings,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggle() async {
    try {
      switch (playback.status) {
        case PlaybackStatus.playing:
          await playback.pause();
        case PlaybackStatus.paused:
          await playback.resume();
        case PlaybackStatus.idle:
          await playback.play(document);
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }

  Future<void> _skip(int delta) async {
    try {
      if (delta < 0) {
        await playback.skipBackward();
      } else {
        await playback.skipForward();
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }

  Future<void> _stop() async {
    try {
      await playback.stop();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: semanticsLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
