import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/app_spacing.dart';
import '../../app/app_surface.dart';
import '../../data/document_store_exception.dart';
import '../../data/markdown_file.dart';
import '../../domain/document_title.dart';
import '../library/library_controller.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({
    required this.controller,
    required this.surface,
    super.key,
  });

  static const titleFieldKey = Key('title-input');
  static const markdownFieldKey = Key('markdown-input');
  static const saveButtonKey = Key('save-document');
  static const pasteHint =
      'Paste Markdown into the field. Choosing a file is optional in the browser.';

  final LibraryController controller;
  final AppSurface surface;

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _titleController = TextEditingController();
  final _markdownController = TextEditingController();
  String? _sourceName;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _markdownController.addListener(_onMarkdownChanged);
  }

  @override
  void dispose() {
    _markdownController.removeListener(_onMarkdownChanged);
    _titleController.dispose();
    _markdownController.dispose();
    super.dispose();
  }

  void _onMarkdownChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);
    final theme = Theme.of(context);
    final sourceName = _sourceName;
    final error = _error;
    final canSave = !_saving && _markdownController.text.trim().isNotEmpty;
    final pasteFirst = widget.surface == AppSurface.web;
    final fileButton = Align(
      alignment: Alignment.centerLeft,
      child: pasteFirst
          ? TextButton.icon(
              onPressed: _saving ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose Markdown file'),
            )
          : OutlinedButton.icon(
              onPressed: _saving ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose Markdown file'),
            ),
    );
    final markdownField = Expanded(
      child: TextField(
        key: ImportScreen.markdownFieldKey,
        controller: _markdownController,
        expands: true,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        decoration: const InputDecoration(
          labelText: 'Markdown',
          alignLabelWithHint: true,
          border: OutlineInputBorder(),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import'),
        actions: [
          TextButton(
            key: ImportScreen.saveButtonKey,
            onPressed: canSave ? _save : null,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: spacing.readingMaxWidth),
            child: Padding(
              padding: EdgeInsets.all(spacing.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: ImportScreen.titleFieldKey,
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: spacing.sectionGap),
                  if (pasteFirst) ...[
                    Text(
                      ImportScreen.pasteHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: spacing.sectionGap),
                  ] else
                    fileButton,
                  if (!pasteFirst && sourceName != null) ...[
                    SizedBox(height: spacing.sectionGap),
                    Text(
                      sourceName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    SizedBox(height: spacing.sectionGap),
                    Text(
                      error,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  SizedBox(height: spacing.sectionGap),
                  markdownField,
                  if (pasteFirst) ...[
                    SizedBox(height: spacing.sectionGap),
                    fileButton,
                    if (sourceName != null) ...[
                      SizedBox(height: spacing.sectionGap),
                      Text(
                        sourceName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose a Markdown file',
      type: FileType.custom,
      allowedExtensions: const ['md', 'markdown'],
    );
    if (!mounted || file == null) return;
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final markdown = decodeMarkdownFile(name: file.name, bytes: bytes);
      _markdownController.text = markdown;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = resolveDocumentTitle(
          markdown: markdown,
          sourceName: file.name,
        );
      }
      setState(() {
        _sourceName = file.name;
        _error = null;
      });
    } on DocumentStoreException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _error = 'Could not read that file. Paste the Markdown instead.';
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final document = await widget.controller.importMarkdown(
        title: _titleController.text,
        markdown: _markdownController.text,
        sourceName: _sourceName,
      );
      if (!mounted) return;
      Navigator.of(context).pop(document.id);
    } on DocumentStoreException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }
}
