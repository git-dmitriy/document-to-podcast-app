import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';

class SystemSpeechBanner extends StatelessWidget {
  const SystemSpeechBanner({super.key});

  static const message = 'This browser can use system speech only.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = AppSpacing.of(context);
    final color = theme.colorScheme.secondaryContainer;
    return ColoredBox(
      color: color,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.pagePadding,
          vertical: spacing.sectionGap,
        ),
        child: Row(
          children: [
            Icon(
              Icons.record_voice_over_outlined,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            SizedBox(width: spacing.sectionGap),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
