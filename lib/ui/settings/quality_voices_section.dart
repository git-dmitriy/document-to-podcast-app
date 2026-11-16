import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';
import '../../app/app_surface.dart';
import '../../domain/voice_install.dart';
import '../../domain/voice_package.dart';
import 'voice_library_controller.dart';

class QualityVoicesSection extends StatelessWidget {
  const QualityVoicesSection({
    required this.voices,
    required this.surface,
    super.key,
  });

  static const webMessage = 'Quality voices are not available in the browser.';

  static Key downloadKey(VoiceId id) => Key('download-${id.name}');

  static Key removeKey(VoiceId id) => Key('remove-${id.name}');

  final VoiceLibraryController voices;
  final AppSurface surface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = AppSpacing.of(context);
    final web = surface == AppSurface.web;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Quality voices', style: theme.textTheme.titleMedium),
        SizedBox(height: spacing.sectionGap / 2),
        Text(
          web
              ? webMessage
              : 'Download Irina and Lessac for offline quality speech.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: spacing.sectionGap),
        if (voices.isLoading)
          const LinearProgressIndicator()
        else
          for (final voice in voiceCatalog) ...[
            _VoiceRow(voice: voice, voices: voices, enabled: !web),
            SizedBox(height: spacing.sectionGap),
          ],
      ],
    );
  }
}

class _VoiceRow extends StatelessWidget {
  const _VoiceRow({
    required this.voice,
    required this.voices,
    required this.enabled,
  });

  final VoicePackage voice;
  final VoiceLibraryController voices;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = AppSpacing.of(context);
    final status = voices.statusOf(voice.id);
    final progress = voices.progressOf(voice.id);
    final error = voices.errorOf(voice.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(voice.title, style: theme.textTheme.titleSmall),
                  Text(
                    voice.languageLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled) _action(status),
          ],
        ),
        if (enabled && status == VoiceInstallStatus.downloading) ...[
          SizedBox(height: spacing.sectionGap / 2),
          LinearProgressIndicator(value: progress?.fraction),
        ],
        if (enabled && error != null) ...[
          SizedBox(height: spacing.sectionGap / 2),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _action(VoiceInstallStatus status) {
    return switch (status) {
      VoiceInstallStatus.downloading => IconButton(
        tooltip: 'Stop ${voice.title} download',
        onPressed: () => voices.cancel(voice.id),
        icon: const Icon(Icons.stop),
      ),
      VoiceInstallStatus.installed => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Installed'),
          TextButton(
            key: QualityVoicesSection.removeKey(voice.id),
            onPressed: () => unawaited(voices.remove(voice.id)),
            child: const Text('Remove'),
          ),
        ],
      ),
      VoiceInstallStatus.partial => FilledButton.tonal(
        key: QualityVoicesSection.downloadKey(voice.id),
        onPressed: () => unawaited(voices.download(voice.id)),
        child: const Text('Resume'),
      ),
      VoiceInstallStatus.missing => FilledButton.tonal(
        key: QualityVoicesSection.downloadKey(voice.id),
        onPressed: () => unawaited(voices.download(voice.id)),
        child: const Text('Download'),
      ),
    };
  }
}
