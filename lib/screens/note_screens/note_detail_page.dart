import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/widgets/text_edit_widget.dart';

import '../../controller/note_controller.dart';
import '../../widgets/alert_dialog.dart';

class NoteDetailPage extends StatefulWidget {
  final Note note;
  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  @override
  void initState() {
    super.initState();
    Get.find<BackgroundController>().getOpacity();
  }

  String _editedLabel() {
    final raw = widget.note.dateTimeEdited;
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateFormat('dd-MM-yyyy hh:mm a').parse(raw);
      return DateFormat.yMMMd().add_jm().format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (derivedTitle, _) = QuillHelper.deriveTitleAndBody(widget.note.content);
    final hasTitle = derivedTitle != 'Untitled';

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => Get.find<NoteController>()
                .shareNote(QuillHelper.convertStringDocumentToString(widget.note.content!)),
          ),
          PopupMenuButton<int>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) {
              if (val == 0) {
                Get.toNamed(AppRoute.getEditNotePage(widget.note));
              } else if (val == 1) {
                _deleteNote(context, widget.note.id!);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 0, child: Text('Edit')),
              PopupMenuItem(value: 1, child: Text('Delete')),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Hero(
        tag: 'note-${widget.note.id}',
        child: Material(
          color: theme.scaffoldBackgroundColor,
          child: GetBuilder<BackgroundController>(
            builder: (_) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          derivedTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: hasTitle
                                ? theme.colorScheme.onSurface
                                : theme.hintColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _editedLabel(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: theme.dividerColor, height: 24),
                  Expanded(
                    child: TextEditWidget(
                      readOnly: true,
                      content: Document.fromJson(jsonDecode(widget.note.content!)),
                      isAddNote: true,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoute.getEditNotePage(widget.note)),
        icon: const Icon(Icons.edit_outlined, size: 20),
        label: const Text(
          'Edit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _deleteNote(BuildContext context, int id) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialogWidget(
        headingText: 'Delete this note?',
        contentText: 'This will delete the note permanently. You cannot undo this action.',
        confirmFunction: () {
          Get.find<NoteController>().deleteNote(id);
          Get.offAllNamed(AppRoute.HOME);
        },
        declineFunction: () => Get.back(),
      ),
    );
  }
}
