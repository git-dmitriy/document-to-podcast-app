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
        return Material(
          color: theme.colorScheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.sectionGap,
                vertical: spacing.sectionGap / 2,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: spacing.sectionGap / 2),
                      child: Text(
                        errorMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
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
