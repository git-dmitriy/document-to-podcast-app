import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../app/app_spacing.dart';
import '../../domain/document.dart';
import '../library/delete_document.dart';
import '../library/library_controller.dart';
import '../settings/settings_controller.dart';
import 'playback_controller.dart';
import 'player_bar.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({
    required this.controller,
    required this.playback,
    required this.settings,
    required this.documentId,
    super.key,
  });

  final LibraryController controller;
  final PlaybackController playback;
  final SettingsController settings;
  final String documentId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final document = controller.state.documentById(documentId);
        return _PlaybackHost(
          controller: controller,
          playback: playback,
          documentId: documentId,
          child: document == null
              ? Scaffold(
                  appBar: AppBar(),
                  body: const Center(
                    child: Text('This document is no longer available.'),
                  ),
                )
              : Scaffold(
                  appBar: AppBar(
                    title: Text(document.title),
                    actions: [
                      IconButton(
                        tooltip: 'Delete ${document.title}',
                        onPressed: () => _delete(context, document),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  body: ReaderBody(document: document),
                  bottomNavigationBar: PlayerBar(
                    playback: playback,
                    settings: settings,
                    document: document,
                  ),
                ),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, Document document) async {
    final removed = await confirmDeleteDocument(context, controller, document);
    if (!context.mounted || !removed) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }
}

class ReaderPane extends StatelessWidget {
  const ReaderPane({
    required this.controller,
    required this.playback,
    required this.settings,
    required this.document,
    super.key,
  });

  final LibraryController controller;
  final PlaybackController playback;
  final SettingsController settings;
  final Document document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = AppSpacing.of(context);
    return _PlaybackHost(
      controller: controller,
      playback: playback,
      documentId: document.id,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.pagePadding,
              spacing.sectionGap,
              spacing.pagePadding,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    document.title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete ${document.title}',
                  onPressed: () {
                    unawaited(
                      confirmDeleteDocument(context, controller, document),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          Expanded(child: ReaderBody(document: document)),
          PlayerBar(playback: playback, settings: settings, document: document),
        ],
      ),
    );
  }
}

class ReaderBody extends StatelessWidget {
  const ReaderBody({required this.document, super.key});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: spacing.readingMaxWidth),
        child: Markdown(
          data: document.markdown,
          selectable: true,
          padding: EdgeInsets.all(spacing.pagePadding),
          styleSheet: MarkdownStyleSheet.fromTheme(theme),
          imageBuilder: _offlineImage,
        ),
      ),
    );
  }
}

class _PlaybackHost extends StatefulWidget {
  const _PlaybackHost({
    required this.controller,
    required this.playback,
    required this.documentId,
    required this.child,
  });

  final LibraryController controller;
  final PlaybackController playback;
  final String documentId;
  final Widget child;

  @override
  State<_PlaybackHost> createState() => _PlaybackHostState();
}

class _PlaybackHostState extends State<_PlaybackHost> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onLibrary);
  }

  @override
  void didUpdateWidget(_PlaybackHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onLibrary);
      widget.controller.addListener(_onLibrary);
    }
    if (oldWidget.documentId != widget.documentId) {
      _stopDocument(oldWidget.documentId);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onLibrary);
    _stopDocument(widget.documentId);
    super.dispose();
  }

  void _onLibrary() {
    if (widget.controller.state.documentById(widget.documentId) == null) {
      _stopDocument(widget.documentId);
    }
  }

  void _stopDocument(String documentId) {
    if (widget.playback.documentId != documentId) return;
    unawaited(_stop());
  }

  Future<void> _stop() async {
    try {
      await widget.playback.stop();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _offlineImage(Uri uri, String? title, String? alt) {
  final label = (alt ?? title ?? '').trim();
  if (label.isEmpty) return const SizedBox.shrink();
  return Text(label);
}
