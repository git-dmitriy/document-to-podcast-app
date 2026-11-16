import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/app_spacing.dart';
import '../../domain/speech_segment.dart';
import '../../domain/tts_engine.dart';
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
  final _scrollController = ScrollController();
  final _keys = <int, GlobalKey>{};
  final _spokenTextKey = GlobalKey();
  var _lastIndex = -1;
  TtsUtteranceProgress? _lastHighlight;
  var _scrollGeneration = 0;

  @override
  void initState() {
    super.initState();
    widget.playback.addListener(_onPlayback);
    widget.playback.utteranceHighlight.addListener(_onHighlight);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_scrollToSpoken(animate: true));
    });
  }

  @override
  void didUpdateWidget(SegmentReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playback != widget.playback) {
      oldWidget.playback.removeListener(_onPlayback);
      oldWidget.playback.utteranceHighlight.removeListener(_onHighlight);
      widget.playback.addListener(_onPlayback);
      widget.playback.utteranceHighlight.addListener(_onHighlight);
    }
    if (oldWidget.segments != widget.segments) {
      _keys.clear();
    }
  }

  @override
  void dispose() {
    _scrollGeneration++;
    widget.playback.removeListener(_onPlayback);
    widget.playback.utteranceHighlight.removeListener(_onHighlight);
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlayback() {
    final index = widget.playback.segmentIndex ?? -1;
    if (index == _lastIndex) return;
    _lastIndex = index;
    _lastHighlight = widget.playback.utteranceHighlight.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_scrollToSpoken(animate: true));
    });
  }

  void _onHighlight() {
    final highlight = widget.playback.utteranceHighlight.value;
    if (highlight == _lastHighlight) return;
    _lastHighlight = highlight;
    if (highlight == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_scrollToSpoken(animate: false));
    });
  }

  Future<void> _scrollToSpoken({required bool animate}) async {
    if (!mounted) return;
    final index = widget.playback.segmentIndex;
    if (index == null || index < 0 || index >= widget.segments.length) return;

    final generation = ++_scrollGeneration;
    // Eager children keep every segment mounted, so keys resolve immediately
    // after the frame that selected them.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || generation != _scrollGeneration) return;

    final highlight = widget.playback.utteranceHighlight.value;
    final textContext = _spokenTextKey.currentContext;
    if (textContext != null && textContext.mounted) {
      _revealContext(
        textContext,
        animate: animate,
        localRect: highlight == null
            ? null
            : _highlightRectFor(textContext, widget.segments[index], highlight),
      );
      return;
    }

    final segmentContext = _keys[index]?.currentContext;
    if (segmentContext == null || !segmentContext.mounted) return;
    _revealContext(segmentContext, animate: animate);
  }

  Rect? _highlightRectFor(
    BuildContext textContext,
    SpeechSegment segment,
    TtsUtteranceProgress highlight,
  ) {
    final renderObject = textContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final theme = Theme.of(textContext);
    return spokenHighlightRect(
      text: segment.text,
      highlight: highlight,
      style: segmentTextStyle(theme, segment.kind)?.copyWith(height: 1.45),
      maxWidth: renderObject.size.width,
      textDirection: Directionality.of(textContext),
    );
  }

  bool _revealContext(
    BuildContext target, {
    required bool animate,
    Rect? localRect,
  }) {
    final renderObject = target.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    final position =
        Scrollable.maybeOf(target)?.position ??
        (_scrollController.hasClients ? _scrollController.position : null);
    if (viewport == null || position == null) return false;

    final revealed = viewport.getOffsetToReveal(
      renderObject,
      0.3,
      rect: localRect,
    );
    final targetOffset = revealed.offset.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if ((position.pixels - targetOffset).abs() < 8) return true;

    if (!animate || (position.pixels - targetOffset).abs() < 96) {
      position.jumpTo(targetOffset);
      return true;
    }

    position.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final current = widget.playback.segmentIndex;
    // Build every passage so follow-along can resolve keys for items that are
    // still below the fold. Narration segment counts stay modest for Markdown.
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: spacing.readingMaxWidth),
        child: ListView(
          controller: _scrollController,
          padding: EdgeInsets.all(spacing.pagePadding),
          children: [
            for (var index = 0; index < widget.segments.length; index++)
              _buildSegment(
                context: context,
                theme: theme,
                spacing: spacing,
                index: index,
                segment: widget.segments[index],
                selected: index == current,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment({
    required BuildContext context,
    required ThemeData theme,
    required AppSpacing spacing,
    required int index,
    required SpeechSegment segment,
    required bool selected,
  }) {
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
            horizontal: spacing.sectionGap * 0.25,
            vertical: spacing.sectionGap * 0.35,
          ),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                width: 3,
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
            ),
          ),
          child: selected
              ? ValueListenableBuilder<TtsUtteranceProgress?>(
                  valueListenable: widget.playback.utteranceHighlight,
                  builder: (context, highlight, _) {
                    return _SegmentBody(
                      segment: segment,
                      selected: true,
                      highlight: highlight,
                      textKey: _spokenTextKey,
                    );
                  },
                )
              : _SegmentBody(
                  segment: segment,
                  selected: false,
                  highlight: null,
                ),
        ),
      ),
    );
  }

  String _label(SpeechSegment segment, bool selected) {
    final prefix = selected ? 'Current passage' : 'Passage';
    return '$prefix, ${segment.language.label}: ${segment.text}';
  }
}

class _SegmentBody extends StatelessWidget {
  const _SegmentBody({
    required this.segment,
    required this.selected,
    required this.highlight,
    this.textKey,
  });

  final SpeechSegment segment;
  final bool selected;
  final TtsUtteranceProgress? highlight;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final baseStyle = segmentTextStyle(theme, segment.kind);
    final muted = theme.colorScheme.onSurfaceVariant;
    final active = theme.colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          segment.language.label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? theme.colorScheme.primary : muted,
          ),
        ),
        SizedBox(height: spacing.sectionGap / 4),
        Text.rich(
          key: textKey,
          TextSpan(
            children: highlightSpans(
              text: segment.text,
              highlight: selected ? highlight : null,
              base: baseStyle?.copyWith(color: active, height: 1.45),
              spoken: baseStyle?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                backgroundColor: theme.colorScheme.primaryContainer,
                height: 1.45,
              ),
              trailing: baseStyle?.copyWith(
                color: muted.withValues(alpha: 0.72),
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

TextStyle? segmentTextStyle(ThemeData theme, SpeechSegmentKind kind) {
  return switch (kind) {
    SpeechSegmentKind.heading => theme.textTheme.titleLarge,
    SpeechSegmentKind.listItem ||
    SpeechSegmentKind.paragraph ||
    SpeechSegmentKind.skip => theme.textTheme.bodyLarge,
  };
}

List<InlineSpan> highlightSpans({
  required String text,
  required TtsUtteranceProgress? highlight,
  required TextStyle? base,
  required TextStyle? spoken,
  required TextStyle? trailing,
}) {
  if (text.isEmpty) return [TextSpan(text: text, style: base)];
  final range = highlight;
  if (range == null) {
    return [TextSpan(text: text, style: base)];
  }
  final start = range.start.clamp(0, text.length);
  final end = range.end.clamp(start, text.length);
  if (end <= start) {
    return [TextSpan(text: text, style: base)];
  }
  return [
    if (start > 0) TextSpan(text: text.substring(0, start), style: base),
    TextSpan(text: text.substring(start, end), style: spoken),
    if (end < text.length) TextSpan(text: text.substring(end), style: trailing),
  ];
}

/// Local rect of [highlight] inside laid-out [text], or null when unknown.
Rect? spokenHighlightRect({
  required String text,
  required TtsUtteranceProgress highlight,
  required TextStyle? style,
  required double maxWidth,
  required TextDirection textDirection,
}) {
  if (text.isEmpty || maxWidth <= 0) return null;
  final start = highlight.start.clamp(0, text.length);
  final end = highlight.end.clamp(start, text.length);
  if (end <= start) return null;

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
  )..layout(maxWidth: maxWidth);
  final boxes = painter.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: end),
  );
  painter.dispose();
  if (boxes.isEmpty) return null;

  var rect = boxes.first.toRect();
  for (var index = 1; index < boxes.length; index++) {
    rect = rect.expandToInclude(boxes[index].toRect());
  }
  return rect;
}
