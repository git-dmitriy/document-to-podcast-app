import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';
import 'quality_prompt_controller.dart';

class QualityVoicesPrompt extends StatelessWidget {
  const QualityVoicesPrompt({
    required this.prompt,
    required this.onOpenSettings,
    super.key,
  });

  static const message =
      'Download Irina and Lessac in Settings for offline quality speech.';
  static const openSettingsKey = Key('quality-prompt-settings');
  static const dismissKey = Key('quality-prompt-dismiss');

  final QualityPromptController prompt;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = AppSpacing.of(context);
    final color = theme.colorScheme.tertiaryContainer;
    return Semantics(
      liveRegion: true,
      label: message,
      child: ColoredBox(
        color: color,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing.pagePadding,
            vertical: spacing.sectionGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              SizedBox(width: spacing.sectionGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Try quality voices',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap / 4),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap / 2),
                    Wrap(
                      spacing: spacing.sectionGap / 2,
                      runSpacing: spacing.sectionGap / 2,
                      children: [
                        TextButton(
                          key: openSettingsKey,
                          onPressed: onOpenSettings,
                          child: const Text('Open Settings'),
                        ),
                        TextButton(
                          key: dismissKey,
                          onPressed: () => unawaited(prompt.dismiss()),
                          child: const Text('Not now'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
