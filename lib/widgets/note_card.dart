import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/helper/color_extension.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/widgets/alert_dialog.dart';
import 'package:my_note_app/widgets/color_picker_sheet.dart';

class NoteCart extends StatefulWidget {
  final Note note;
  final int index;
  const NoteCart({super.key, required this.note, required this.index});

  @override
  State<NoteCart> createState() => _NoteCartState();
}

class _NoteCartState extends State<NoteCart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  String _editedLabel() {
    final raw = widget.note.dateTimeEdited;
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = widget.note.editedDateTime;
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
    final hex = widget.note.color;
    if (hex == null || hex.isEmpty) return Theme.of(context).dividerColor;
    try {
      return hex.toColor() as Color;
    } catch (_) {
      return Theme.of(context).dividerColor;
    }
  }

  void _handleTap(NoteController ctrl) {
    if (ctrl.isSelectionMode) {
      HapticFeedback.selectionClick();
      ctrl.toggleSelection(widget.note.id!);
    } else {
      Get.toNamed(AppRoute.getNoteDetailsPage(widget.note));
    }
  }

  void _handleLongPress(NoteController ctrl) {
    HapticFeedback.mediumImpact();
    ctrl.toggleSelection(widget.note.id!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = Get.find<NoteController>();
    final (derivedTitle, derivedBody) =
        QuillHelper.deriveTitleAndBody(widget.note.content);
    final hasTitle = derivedTitle != 'Untitled';
    final isFav = widget.note.isFavorite == 1;
    final isSelecting = ctrl.isSelectionMode;
    final isSelected = ctrl.selectedIds.contains(widget.note.id);

    return Hero(
      tag: 'note-${widget.note.id}',
      child: ScaleTransition(
        scale: _pressScale,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTapDown: (_) => _pressController.forward(),
            onTap: () {
              _pressController.reverse();
              _handleTap(ctrl);
            },
            onTapCancel: () => _pressController.reverse(),
            onLongPress: () => _handleLongPress(ctrl),
            child: ctrl.cardDesignIndex == 1
                ? _buildTintedCard(theme, ctrl, derivedTitle, derivedBody, hasTitle, isFav, isSelecting, isSelected)
                : ctrl.cardDesignIndex == 2
                    ? _buildMinimalistCard(theme, ctrl, derivedTitle, derivedBody, hasTitle, isFav, isSelecting, isSelected)
                    : _buildClassicCard(theme, ctrl, derivedTitle, derivedBody, hasTitle, isFav, isSelecting, isSelected),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicCard(ThemeData theme, NoteController ctrl, String derivedTitle, String derivedBody, bool hasTitle, bool isFav, bool isSelecting, bool isSelected) {
    return AnimatedContainer(
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
                color: isSelected ? theme.colorScheme.primary : _accent(context),
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
                              color: hasTitle ? theme.colorScheme.onSurface : theme.hintColor,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, top: 2),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.elasticOut,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                            child: isSelecting
                                ? _SelectionCircle(key: const ValueKey('circle'), isSelected: isSelected, theme: theme)
                                : GestureDetector(
                                    key: const ValueKey('bookmark'),
                                    onTap: () => ctrl.favoriteNote(widget.note.id!),
                                    child: Icon(
                                      isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                      size: 18,
                                      color: isFav ? theme.colorScheme.onSurface : theme.hintColor,
                                    ),
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
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, height: 1.45, fontSize: 13),
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
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.hintColor, fontSize: 11, letterSpacing: 0.1),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isSelecting
                              ? const SizedBox(key: ValueKey('no-menu'), width: 24)
                              : _MenuButton(key: const ValueKey('menu'), note: widget.note, onDeleteTap: () => _confirmDelete(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTintedCard(ThemeData theme, NoteController ctrl, String derivedTitle, String derivedBody, bool hasTitle, bool isFav, bool isSelecting, bool isSelected) {
    final baseColor = _accent(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.15)
        : Color.alphaBlend(baseColor.withValues(alpha: isDark ? 0.12 : 0.08), theme.cardColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : baseColor.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
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
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.3,
                    color: hasTitle ? theme.colorScheme.onSurface : theme.hintColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: isSelecting
                      ? _SelectionCircle(key: const ValueKey('circle'), isSelected: isSelected, theme: theme)
                      : GestureDetector(
                          key: const ValueKey('bookmark'),
                          onTap: () => ctrl.favoriteNote(widget.note.id!),
                          child: Icon(
                            isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            size: 20,
                            color: isFav ? baseColor : theme.hintColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (derivedBody.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              derivedBody,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.5,
                fontSize: 13.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  _editedLabel(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelecting
                    ? const SizedBox(key: ValueKey('no-menu'), width: 24)
                    : _MenuButton(key: const ValueKey('menu'), note: widget.note, onDeleteTap: () => _confirmDelete(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalistCard(ThemeData theme, NoteController ctrl, String derivedTitle, String derivedBody, bool hasTitle, bool isFav, bool isSelecting, bool isSelected) {
    final baseColor = _accent(context);
    final hasColor = widget.note.color != null && widget.note.color!.isNotEmpty && widget.note.color != '#FFA0A4A8';
    final borderColor = isSelected 
        ? theme.colorScheme.primary 
        : (hasColor ? baseColor.withValues(alpha: 0.8) : theme.dividerColor);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasColor ? baseColor.withValues(alpha: 0.05) : theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.0 : 1.5,
        ),
      ),
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
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: hasTitle ? theme.colorScheme.onSurface : theme.hintColor,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: isSelecting
                      ? _SelectionCircle(key: const ValueKey('circle'), isSelected: isSelected, theme: theme)
                      : GestureDetector(
                          key: const ValueKey('bookmark'),
                          onTap: () => ctrl.favoriteNote(widget.note.id!),
                          child: Icon(
                            isFav ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 20,
                            color: isFav ? Colors.amber.shade600 : theme.hintColor.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (derivedBody.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              derivedBody,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  _editedLabel().toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    fontSize: 10,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: isSelecting
                    ? const SizedBox(key: ValueKey('no-menu'), width: 24)
                    : _MenuButton(key: const ValueKey('menu'), note: widget.note, onDeleteTap: () => _confirmDelete(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialogWidget(
        headingText: 'Delete this note?',
        contentText:
            'This note will be moved to the Recycle Bin. You can restore it within 30 days.',
        confirmFunction: () {
          Get.find<NoteController>().deleteNote(widget.note.id!);
          Get.back();
        },
        declineFunction: () => Get.back(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated selection circle (checkmark indicator)
// ─────────────────────────────────────────────────────────────────────────────
class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({
    super.key,
    required this.isSelected,
    required this.theme,
  });
  final bool isSelected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : theme.hintColor,
          width: 1.5,
        ),
      ),
      child: AnimatedScale(
        scale: isSelected ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.elasticOut,
        child: Icon(
          Icons.check_rounded,
          size: 13,
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Note card popup menu (extracted so AnimatedSwitcher has clean keys)
// ─────────────────────────────────────────────────────────────────────────────
class _MenuButton extends StatelessWidget {
  const _MenuButton({
    super.key,
    required this.note,
    required this.onDeleteTap,
  });
  final Note note;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
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
            onDeleteTap();
            break;
          case 2:
            Get.find<NoteController>().shareNote(
                QuillHelper.convertStringDocumentToString(note.content!));
            break;
          case 3:
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) => ColorPickerSheet(
                currentColor: note.color ?? '#FFA0A4A8',
                onSelected: (hex) =>
                    Get.find<NoteController>().updateNoteColor(note.id!, hex),
              ),
            );
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 0, child: Text('Edit')),
        PopupMenuItem(value: 2, child: Text('Share')),
        PopupMenuItem(value: 3, child: Text('Change color')),
        PopupMenuItem(value: 1, child: Text('Delete')),
      ],
    );
  }
}
