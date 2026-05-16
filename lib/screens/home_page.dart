import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/screens/note_screens/search_screen.dart';
import 'package:my_note_app/widgets/drawer_widget.dart';
import 'package:my_note_app/widgets/note_card.dart';
import '../controller/note_controller.dart';
import '../widgets/alert_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GetBuilder<NoteController>(
      builder: (controller) {
        final favourites =
            controller.notes.where((n) => n.isFavorite == 1).toList();
        final displayNotes =
            controller.showFavouritesOnly ? favourites : controller.notes;
        final isSelecting = controller.isSelectionMode;
        final selectedCount = controller.selectedIds.length;
        final allSelected = displayNotes.isNotEmpty &&
            controller.selectedIds
                .containsAll(displayNotes.map((n) => n.id!));

        return PopScope(
          canPop: !isSelecting,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.clearSelection();
          },
          child: Scaffold(
            // Always keep the drawer so Scaffold.of(ctx).openDrawer() works.
            drawer: const DrawerWidget(),
            appBar: AppBar(
              // ── Leading: hamburger ↔ close ─────────────────────────────
              leading: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: RotationTransition(
                    turns: Tween<double>(begin: 0.12, end: 0.0)
                        .animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    )),
                    child: child,
                  ),
                ),
                child: isSelecting
                    ? IconButton(
                        key: const ValueKey('close'),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Cancel',
                        onPressed: controller.clearSelection,
                      )
                    : Builder(
                        key: const ValueKey('menu'),
                        builder: (ctx) => IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          tooltip: 'Menu',
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
              ),
              // ── Title: "Notes" ↔ "N selected" ─────────────────────────
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
                            'Notes',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (controller.notes.isNotEmpty)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                key: ValueKey(controller.notes.length),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      theme.dividerColor.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${controller.notes.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              // ── Actions: normal ↔ selection ────────────────────────────
              actions: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerRight,
                    children: [...previous, if (current != null) current],
                  ),
                  child: isSelecting
                      ? _SelectionActions(
                          key: const ValueKey('sel-actions'),
                          allSelected: allSelected,
                          displayNotes: displayNotes,
                          controller: controller,
                          onDelete: () => _confirmDeleteSelected(
                              context, controller, selectedCount),
                        )
                      : _NormalActions(
                          key: const ValueKey('norm-actions'),
                          context: context,
                          controller: controller,
                        ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter chips collapse smoothly when entering selection mode
                ClipRect(
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeInOut,
                    child: isSelecting
                        ? const SizedBox.shrink()
                        : _FilterChips(
                            controller: controller,
                            favCount: favourites.length,
                          ),
                  ),
                ),
                Expanded(
                  child: displayNotes.isEmpty
                      ? _EmptyState(
                          isFavouritesFilter: controller.showFavouritesOnly)
                      : _NotesGrid(notes: displayNotes),
                ),
              ],
            ),
            // FAB scales out when entering selection mode
            floatingActionButton: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: isSelecting
                  ? const SizedBox.shrink()
                  : FloatingActionButton.extended(
                      key: const ValueKey('fab'),
                      onPressed: () => Get.toNamed(AppRoute.ADD_NEW_NOTE),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text(
                        'New note',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, letterSpacing: -0.1),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteSelected(
      BuildContext context, NoteController controller, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialogWidget(
        headingText: 'Delete $count ${count == 1 ? 'note' : 'notes'}?',
        contentText:
            'This will permanently delete the selected ${count == 1 ? 'note' : 'notes'}. You cannot undo this action.',
        confirmFunction: () {
          controller.deleteSelectedNotes();
          Get.back();
        },
        declineFunction: () => Get.back(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted widgets — keep build method clean and give AnimatedSwitcher
// stable widget types to diff against.
// ─────────────────────────────────────────────────────────────────────────────

class _NormalActions extends StatelessWidget {
  const _NormalActions({
    super.key,
    required this.context,
    required this.controller,
  });
  final BuildContext context;
  final NoteController controller;

  @override
  Widget build(BuildContext ctx) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.isPasswordActive() || controller.isBiometricLockActive())
          IconButton(
            tooltip: 'Lock App',
            icon: const Icon(Icons.lock_outline_rounded),
            onPressed: () {
              controller.setSessionUnlocked(false);
              Get.offAllNamed(AppRoute.pass);
            },
          ),
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search_rounded),
          onPressed: () =>
              showSearch(context: context, delegate: Search()),
        ),
        PopupMenuButton<int>(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (val) {
            if (val == 0) {
              showDialog(
                context: context,
                builder: (_) => AlertDialogWidget(
                  headingText: 'Delete all notes?',
                  contentText:
                      'This will delete all notes permanently. You cannot undo this action.',
                  confirmFunction: () {
                    controller.deleteAllNotes();
                    Get.back();
                  },
                  declineFunction: () => Get.back(),
                ),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 0, child: Text('Delete all notes')),
          ],
        ),
      ],
    );
  }
}

class _SelectionActions extends StatelessWidget {
  const _SelectionActions({
    super.key,
    required this.allSelected,
    required this.displayNotes,
    required this.controller,
    required this.onDelete,
  });
  final bool allSelected;
  final List<Note> displayNotes;
  final NoteController controller;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: allSelected ? 'Deselect all' : 'Select all',
          icon: Icon(allSelected
              ? Icons.deselect_rounded
              : Icons.select_all_rounded),
          onPressed: () {
            if (allSelected) {
              controller.clearSelection();
            } else {
              controller.selectAll(displayNotes);
            }
          },
        ),
        IconButton(
          tooltip: 'Delete selected',
          icon: Icon(Icons.delete_outline_rounded,
              color: theme.colorScheme.error),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.controller,
    required this.favCount,
  });
  final NoteController controller;
  final int favCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          _Chip(
            label: 'All',
            count: controller.notes.length,
            selected: !controller.showFavouritesOnly,
            onTap: () {
              if (controller.showFavouritesOnly) {
                controller.toggleFavouritesFilter();
              }
            },
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Bookmarked',
            count: favCount,
            selected: controller.showFavouritesOnly,
            icon: Icons.bookmark_rounded,
            onTap: () {
              if (!controller.showFavouritesOnly) {
                controller.toggleFavouritesFilter();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              selected ? theme.colorScheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? theme.colorScheme.onSurface
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color:
                    selected ? theme.colorScheme.surface : theme.hintColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected
                    ? theme.colorScheme.surface
                    : theme.hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 5),
              Text(
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: selected
                      ? theme.colorScheme.surface.withValues(alpha: 0.7)
                      : theme.hintColor.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotesGrid extends StatelessWidget {
  const _NotesGrid({required this.notes});
  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final layoutIndex = Get.find<NoteController>().layoutIndex;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        child: layoutIndex == 2
            ? SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: StaggeredGrid.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  children: List.generate(notes.length, (index) {
                    // Mathematically perfect pattern to avoid empty space
                    // [2, 1] = 3, [1, 1, 1] = 3, [1, 2] = 3
                    const pattern = [2, 1, 1, 1, 1, 1, 2];
                    final span = pattern[index % pattern.length];
                    return StaggeredGridTile.fit(
                      crossAxisCellCount: span,
                      child: NoteCart(note: notes[index], index: index),
                    );
                  }),
                ),
              )
            : layoutIndex == 3
                ? GridView.custom(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverQuiltedGridDelegate(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      repeatPattern: QuiltedGridRepeatPattern.inverted,
                      pattern: const [
                        QuiltedGridTile(2, 2),
                        QuiltedGridTile(1, 1),
                        QuiltedGridTile(1, 1),
                      ],
                    ),
                    childrenDelegate: SliverChildBuilderDelegate(
                      (context, index) => ClipRect(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: NoteCart(note: notes[index], index: index),
                        ),
                      ),
                      childCount: notes.length,
                    ),
                  )
                : MasonryGridView.count(
                    crossAxisCount: layoutIndex == 1 ? 1 : 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    itemCount: notes.length,
                    itemBuilder: (context, index) =>
                        NoteCart(note: notes[index], index: index),
                  ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isFavouritesFilter});
  final bool isFavouritesFilter;

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
                isFavouritesFilter
                    ? Icons.bookmark_border_rounded
                    : Icons.edit_note_rounded,
                size: 44,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFavouritesFilter ? 'No bookmarks yet' : 'No notes yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFavouritesFilter
                  ? 'Tap the bookmark icon on any note to save it here.'
                  : 'Capture an idea, a thought, or a reminder.\nTap the button below to begin.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.5,
              ),
            ),
            if (!isFavouritesFilter) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoute.ADD_NEW_NOTE),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Create your first note',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
