import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';
import '../../domain/speech_segment.dart';
import 'playback_controller.dart';

class SegmentReader extends StatefulWidget {
  const SegmentReader({
    required this.playback,
    required this.segments,
    super.key,
  });

  final PlaybackController playback;
  final List<SpeechSegment> segments;

  @override
  State<SegmentReader> createState() => _SegmentReaderState();
}

class _SegmentReaderState extends State<SegmentReader> {
  final _keys = <int, GlobalKey>{};
  var _lastIndex = -1;

  @override
  void initState() {
    super.initState();
    widget.playback.addListener(_onPlayback);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(SegmentReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback != widget.playback) {
      oldWidget.playback.removeListener(_onPlayback);
      widget.playback.addListener(_onPlayback);
    }
    if (oldWidget.segments != widget.segments) {
      _keys.clear();
    }
  }

  @override
  void dispose() {
    widget.playback.removeListener(_onPlayback);
    super.dispose();
  }

  void _onPlayback() {
    final index = widget.playback.segmentIndex ?? -1;
    if (index == _lastIndex) return;
    _lastIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  void _scrollToCurrent() {
    if (!mounted) return;
    final index = widget.playback.segmentIndex;
    if (index == null) return;
    final key = _keys[index];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 280),
      alignment: 0.2,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final current = widget.playback.segmentIndex;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: spacing.readingMaxWidth),
        child: ListView.builder(
          padding: EdgeInsets.all(spacing.pagePadding),
          itemCount: widget.segments.length,
          itemBuilder: (context, index) {
            final segment = widget.segments[index];
            final selected = index == current;
            final key = _keys.putIfAbsent(index, GlobalKey.new);
            return Padding(
              key: key,
              padding: EdgeInsets.only(bottom: spacing.sectionGap),
              child: Semantics(
                container: true,
                selected: selected,
                label: _label(segment, selected),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.sectionGap,
                    vertical: spacing.sectionGap * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        segment.language.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: spacing.sectionGap / 4),
                      Text(
                        segment.text,
                        style: _textStyle(theme, segment.kind)?.copyWith(
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  TextStyle? _textStyle(ThemeData theme, SpeechSegmentKind kind) {
    return switch (kind) {
      SpeechSegmentKind.heading => theme.textTheme.titleLarge,
      SpeechSegmentKind.listItem ||
      SpeechSegmentKind.paragraph ||
      SpeechSegmentKind.skip => theme.textTheme.bodyLarge,
    };
  }

  String _label(SpeechSegment segment, bool selected) {
    final prefix = selected ? 'Current passage' : 'Passage';
    return '$prefix, ${segment.language.label}: ${segment.text}';
  }
}
