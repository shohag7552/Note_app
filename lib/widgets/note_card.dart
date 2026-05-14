import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/helper/color_extension.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/widgets/alert_dialog.dart';

class NoteCart extends StatelessWidget {
  final Note note;
  final int index;
  const NoteCart({super.key, required this.note, required this.index});

  String _editedLabel() {
    final raw = note.dateTimeEdited;
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateFormat('dd-MM-yyyy hh:mm a').parse(raw);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return DateFormat.yMMMd().format(dt);
    } catch (_) {
      return raw;
    }
  }

  Color _accent(BuildContext context) {
    final hex = note.color;
    if (hex == null || hex.isEmpty) {
      return Theme.of(context).dividerColor;
    }
    try {
      return hex.toColor() as Color;
    } catch (_) {
      return Theme.of(context).dividerColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (derivedTitle, derivedBody) = QuillHelper.deriveTitleAndBody(note.content);
    final hasTitle = derivedTitle != 'Untitled';
    final isFav = note.isFavorite == 1;

    return Hero(
      tag: 'note-${note.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Get.toNamed(AppRoute.getNoteDetailsPage(note)),
          onLongPress: () => _confirmDelete(context),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: _accent(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  derivedTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                    letterSpacing: -0.2,
                                    color: hasTitle
                                        ? theme.colorScheme.onSurface
                                        : theme.hintColor,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    Get.find<NoteController>().favoriteNote(note.id!),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4, top: 2),
                                  child: Icon(
                                    isFav
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_border_rounded,
                                    size: 18,
                                    color: isFav
                                        ? theme.colorScheme.onSurface
                                        : theme.hintColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (derivedBody.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Expanded(
                              child: Text(
                                derivedBody,
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                  height: 1.45,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _editedLabel(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.hintColor,
                                    fontSize: 11,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              _menu(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<int>(
      tooltip: 'More',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_horiz, size: 18, color: theme.hintColor),
      onSelected: (value) {
        switch (value) {
          case 0:
            Get.toNamed(AppRoute.getEditNotePage(note));
            break;
          case 1:
            _confirmDelete(context);
            break;
          case 2:
            Get.find<NoteController>()
                .shareNote(QuillHelper.convertStringDocumentToString(note.content!));
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 0, child: Text('Edit')),
        PopupMenuItem(value: 2, child: Text('Share')),
        PopupMenuItem(value: 1, child: Text('Delete')),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialogWidget(
        headingText: 'Delete this note?',
        contentText: 'This will delete the note permanently. You cannot undo this action.',
        confirmFunction: () {
          Get.find<NoteController>().deleteNote(note.id!);
          Get.back();
        },
        declineFunction: () => Get.back(),
      ),
    );
  }
}
