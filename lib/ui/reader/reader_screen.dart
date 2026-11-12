import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../app/app_spacing.dart';
import '../../domain/document.dart';
import '../library/delete_document.dart';
import '../library/library_controller.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({
    required this.controller,
    required this.documentId,
    super.key,
  });

  final LibraryController controller;
  final String documentId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final document = controller.state.documentById(documentId);
        if (document == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('This document is no longer available.'),
            ),
          );
        }
        return Scaffold(
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
    required this.document,
    super.key,
  });

  final LibraryController controller;
  final Document document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = AppSpacing.of(context);
    return Column(
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
                child: Text(document.title, style: theme.textTheme.titleLarge),
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
      ],
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

Widget _offlineImage(Uri uri, String? title, String? alt) {
  final label = (alt ?? title ?? '').trim();
  if (label.isEmpty) return const SizedBox.shrink();
  return Text(label);
}
