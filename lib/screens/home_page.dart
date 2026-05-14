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
        return Scaffold(
          appBar: AppBar(
            title: Row(
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.6),
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
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded),
                onPressed: () => showSearch(context: context, delegate: Search()),
              ),
              PopupMenuButton<int>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 0) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialogWidget(
                          headingText: 'Delete all notes?',
                          contentText:
                              'This will delete all notes permanently. You cannot undo this action.',
                          confirmFunction: () {
                            controller.deleteAllNotes();
                            Get.back();
                          },
                          declineFunction: () => Get.back(),
                        );
                      },
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 0, child: Text('Delete all notes')),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          drawer: const DrawerWidget(),
          body: GetBuilder<NoteController>(
            builder: (_) {
              final favourites = controller.notes
                  .where((n) => n.isFavorite == 1)
                  .toList();
              final displayNotes = controller.showFavouritesOnly
                  ? favourites
                  : controller.notes;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filterChips(context, controller, favourites.length),
                  Expanded(
                    child: displayNotes.isEmpty
                        ? _emptyState(context,
                            isFavouritesFilter: controller.showFavouritesOnly)
                        : _notesGrid(context, displayNotes),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Get.toNamed(AppRoute.ADD_NEW_NOTE),
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: const Text(
              'New note',
              style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.1),
            ),
          ),
        );
      },
    );
  }

  Widget _filterChips(BuildContext context, NoteController controller, int favCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          _chip(
            context,
            label: 'All',
            count: controller.notes.length,
            selected: !controller.showFavouritesOnly,
            onTap: () {
              if (controller.showFavouritesOnly) controller.toggleFavouritesFilter();
            },
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Bookmarked',
            count: favCount,
            selected: controller.showFavouritesOnly,
            icon: Icons.bookmark_rounded,
            onTap: () {
              if (!controller.showFavouritesOnly) controller.toggleFavouritesFilter();
            },
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.onSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? theme.colorScheme.onSurface : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? theme.colorScheme.surface : theme.hintColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: selected ? theme.colorScheme.surface : theme.hintColor,
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

  Widget _notesGrid(BuildContext context, List<Note> notes) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 90),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return NoteCart(note: notes[index], index: index);
          },
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, {bool isFavouritesFilter = false}) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
