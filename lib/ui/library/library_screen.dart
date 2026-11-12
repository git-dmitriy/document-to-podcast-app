import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_spacing.dart';
import '../../app/window_size.dart';
import '../../domain/document.dart';
import '../import/import_screen.dart';
import '../reader/reader_screen.dart';
import 'delete_document.dart';
import 'document_list.dart';
import 'library_controller.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({required this.controller, super.key});

  static const emptyImportKey = Key('empty-import');

  final LibraryController controller;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.load());
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            tooltip: 'Import Markdown',
            onPressed: _openImport,
            icon: const Icon(Icons.note_add_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final state = widget.controller.state;
            final twoPanes = WindowSize.fromWidth(
              MediaQuery.sizeOf(context).width,
            ).showsTwoPanes;
            final list = _LibraryBody(
              state: state,
              spacing: spacing,
              onImport: _openImport,
              onRetry: _retry,
              onOpen: (document) => _openDocument(document, twoPanes: twoPanes),
              onDelete: _delete,
            );
            if (!twoPanes) return list;
            return Row(
              children: [
                SizedBox(width: 360, child: list),
                const VerticalDivider(width: 1),
                Expanded(child: _detail(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _detail(LibraryState state) {
    final selectedId = state.selectedId;
    final document = selectedId == null ? null : state.documentById(selectedId);
    if (document == null) {
      return const Center(child: Text('Select a document to read.'));
    }
    return ReaderPane(controller: widget.controller, document: document);
  }

  Future<void> _openImport() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (context) => ImportScreen(controller: widget.controller),
      ),
    );
    if (!mounted || id == null) return;
    widget.controller.select(id);
  }

  Future<void> _retry() async {
    await widget.controller.load();
  }

  void _openDocument(Document document, {required bool twoPanes}) {
    widget.controller.select(document.id);
    if (twoPanes) return;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => ReaderScreen(
            controller: widget.controller,
            documentId: document.id,
          ),
        ),
      ),
    );
  }

  Future<void> _delete(Document document) async {
    await confirmDeleteDocument(context, widget.controller, document);
  }
}

class _LibraryBody extends StatelessWidget {
  const _LibraryBody({
    required this.state,
    required this.spacing,
    required this.onImport,
    required this.onRetry,
    required this.onOpen,
    required this.onDelete,
  });

  final LibraryState state;
  final AppSpacing spacing;
  final VoidCallback onImport;
  final Future<void> Function() onRetry;
  final ValueChanged<Document> onOpen;
  final ValueChanged<Document> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (state.isLoading && state.documents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final errorMessage = state.errorMessage;
    if (errorMessage != null && state.documents.isEmpty) {
      return _MessagePane(
        spacing: spacing,
        title: errorMessage,
        action: FilledButton(
          onPressed: () => unawaited(onRetry()),
          child: const Text('Retry'),
        ),
      );
    }
    if (state.documents.isEmpty) {
      return _MessagePane(
        spacing: spacing,
        title: 'No documents yet',
        body:
            'Import a Markdown file or paste text to start a reading library.',
        action: FilledButton(
          key: LibraryScreen.emptyImportKey,
          onPressed: onImport,
          child: const Text('Import Markdown'),
        ),
      );
    }
    return Column(
      children: [
        if (errorMessage != null)
          Padding(
            padding: EdgeInsets.all(spacing.pagePadding),
            child: Text(
              errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        Expanded(
          child: DocumentList(
            documents: state.documents,
            selectedId: state.selectedId,
            onOpen: onOpen,
            onDelete: onDelete,
          ),
        ),
      ],
    );
  }
}

class _MessagePane extends StatelessWidget {
  const _MessagePane({
    required this.spacing,
    required this.title,
    required this.action,
    this.body,
  });

  final AppSpacing spacing;
  final String title;
  final String? body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = this.body;
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.all(spacing.pagePadding),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (body != null) ...[
                      SizedBox(height: spacing.sectionGap),
                      Text(
                        body,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(height: spacing.sectionGap),
                    action,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
