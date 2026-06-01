import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/helper/color_extension.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<NoteController>().getAllDeletedNotes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<NoteController>(
      builder: (controller) {
        final trashed = controller.deletedNotes;
        final isSelecting = controller.isSelectionMode;
        final selectedCount = controller.selectedIds.length;
        final allSelected = trashed.isNotEmpty &&
            controller.selectedIds.containsAll(trashed.map((n) => n.id!));

        return PopScope(
          canPop: !isSelecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.clearSelection();
          },
          child: Scaffold(
            appBar: AppBar(
              leading: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: isSelecting
                    ? IconButton(
                        key: const ValueKey('close'),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cancel',
                        onPressed: controller.clearSelection,
                      )
                    : const BackButton(key: ValueKey('back')),
              ),
              title: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.25),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                ),
                child: isSelecting
                    ? Text(
                        '$selectedCount selected',
                        key: ValueKey('sel-$selectedCount'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      )
                    : Row(
                        key: const ValueKey('title'),
                        children: [
                          Text(
                            'Recycle Bin',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (trashed.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    theme.dividerColor.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${trashed.length}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
              actions: [
                if (isSelecting) ...[
                  IconButton(
                    tooltip: allSelected ? 'Deselect all' : 'Select all',
                    icon: Icon(allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded),
                    onPressed: () {
                      if (allSelected) {
                        controller.clearSelection();
                      } else {
                        controller.selectAll(trashed);
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Restore selected',
                    icon: Icon(Icons.restore_rounded,
                        color: theme.colorScheme.primary),
                    onPressed: () => _confirmRestoreSelected(
                        context, controller, selectedCount),
                  ),
                  IconButton(
                    tooltip: 'Delete permanently',
                    icon: Icon(Icons.delete_forever_rounded,
                        color: theme.colorScheme.error),
                    onPressed: () => _confirmPermanentDeleteSelected(
                        context, controller, selectedCount),
                  ),
                ] else if (trashed.isNotEmpty)
                  PopupMenuButton<int>(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (val) {
                      if (val == 0) {
                        _confirmEmptyTrash(context, controller, trashed.length);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 0,
                        child: Row(
                          children: [
                            Icon(Icons.delete_forever_rounded,
                                size: 20, color: theme.colorScheme.error),
                            const SizedBox(width: 10),
                            const Text('Empty recycle bin'),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
              ],
            ),
            body: Column(
              children: [
                if (trashed.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 16,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Notes are automatically deleted after 30 days',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: trashed.isEmpty
                      ? _EmptyTrashState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 80),
                          physics: const BouncingScrollPhysics(),
                          itemCount: trashed.length,
                          itemBuilder: (context, index) {
                            return _TrashNoteCard(
                              note: trashed[index],
                              isSelecting: isSelecting,
                              isSelected: controller.selectedIds
                                  .contains(trashed[index].id),
                              onTap: () {
                                if (isSelecting) {
                                  HapticFeedback.selectionClick();
                                  controller
                                      .toggleSelection(trashed[index].id!);
                                }
                              },
                              onLongPress: () {
                                HapticFeedback.mediumImpact();
                                controller.toggleSelection(trashed[index].id!);
                              },
                              onRestore: () => _confirmRestore(
                                  context, controller, trashed[index]),
                              onDelete: () => _confirmPermanentDelete(
                                  context, controller, trashed[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmRestore(
      BuildContext context, NoteController controller, Note note) {
    controller.restoreNote(note.id!);
    Get.snackbar(
      'Note Restored',
      'The note has been moved back to your notes.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
    );
  }

  void _confirmRestoreSelected(
      BuildContext context, NoteController controller, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Restore $count ${count == 1 ? 'note' : 'notes'}?'),
        content: Text(
            'The selected ${count == 1 ? 'note' : 'notes'} will be moved back to your notes list.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.restoreSelectedNotes();
              Get.back();
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDelete(
      BuildContext context, NoteController controller, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete permanently?'),
        content: const Text(
            'This note will be permanently deleted. You cannot undo this action.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.permanentlyDeleteNote(note.id!);
              Get.back();
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentDeleteSelected(
      BuildContext context, NoteController controller, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
            'Permanently delete $count ${count == 1 ? 'note' : 'notes'}?'),
        content: const Text(
            'These notes will be permanently deleted. You cannot undo this action.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.permanentlyDeleteSelectedNotes();
              Get.back();
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(
      BuildContext context, NoteController controller, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Empty recycle bin?'),
        content: Text(
            'All $count ${count == 1 ? 'note' : 'notes'} in the recycle bin will be permanently deleted. You cannot undo this action.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              controller.emptyTrash();
              Get.back();
            },
            child: Text('Empty',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty trash state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyTrashState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: theme.cardColor,
                shape: BoxShape.circle,
                border: Border.all(color: theme.dividerColor),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                size: 44,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Recycle bin is empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Deleted notes will appear here\nfor 30 days before being removed.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Trash note card
// ─────────────────────────────────────────────────────────────────────────────
class _TrashNoteCard extends StatelessWidget {
  final Note note;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashNoteCard({
    required this.note,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onRestore,
    required this.onDelete,
  });

  String _deletedLabel() {
    final raw = note.deletedAt;
    if (raw == null || raw.isEmpty) return 'Deleted';
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now().toUtc();
      final diff = now.difference(dt);
      final daysLeft = 30 - diff.inDays;
      if (daysLeft <= 0) return 'Expires soon';
      if (daysLeft == 1) return '1 day left';
      return '$daysLeft days left';
    } catch (_) {
      return 'Deleted';
    }
  }

  Color _accent(BuildContext context) {
    final hex = note.color;
    if (hex == null || hex.isEmpty) return Theme.of(context).dividerColor;
    try {
      return hex.toColor() as Color;
    } catch (_) {
      return Theme.of(context).dividerColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (derivedTitle, derivedBody) =
        QuillHelper.deriveTitleAndBody(note.content);
    final hasTitle = derivedTitle != 'Untitled';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.dividerColor,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    width: 4,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : _accent(context).withValues(alpha: 0.5),
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
                                  style:
                                      theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.25,
                                    letterSpacing: -0.2,
                                    color: hasTitle
                                        ? theme.colorScheme.onSurface
                                        : theme.hintColor,
                                  ),
                                ),
                              ),
                              if (isSelecting)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, top: 2),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.hintColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: AnimatedScale(
                                      scale: isSelected ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.elasticOut,
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (derivedBody.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              derivedBody,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                                height: 1.45,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded,
                                  size: 12, color: theme.hintColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _deletedLabel(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      theme.textTheme.labelSmall?.copyWith(
                                    color: theme.hintColor,
                                    fontSize: 11,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                              ),
                              if (!isSelecting) ...[
                                _ActionChip(
                                  icon: Icons.restore_rounded,
                                  label: 'Restore',
                                  color: theme.colorScheme.primary,
                                  onTap: onRestore,
                                ),
                                const SizedBox(width: 6),
                                _ActionChip(
                                  icon: Icons.delete_forever_rounded,
                                  label: 'Delete',
                                  color: theme.colorScheme.error,
                                  onTap: onDelete,
                                ),
                              ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Action chip (Restore / Delete)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
