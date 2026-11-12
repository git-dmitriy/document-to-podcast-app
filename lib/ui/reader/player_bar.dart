import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';
import '../../domain/document.dart';
import 'playback_controller.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({required this.playback, required this.document, super.key});

  final PlaybackController playback;
  final Document document;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: playback,
      builder: (context, _) {
        final theme = Theme.of(context);
        final spacing = AppSpacing.of(context);
        final errorMessage = playback.errorMessage;
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
                        child: Slider(
                          value: playback.rate,
                          min: PlaybackController.minRate,
                          max: PlaybackController.maxRate,
                          onChanged: (value) {
                            unawaited(playback.setRate(value));
                          },
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
