import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/widgets/note_card.dart';
import '../../controller/note_controller.dart';

class Search extends SearchDelegate {
  final NoteController controller = Get.find<NoteController>();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if (query.isNotEmpty) {
            query = "";
          } else {
            Get.back();
          }
        },
        icon: Icon(Icons.clear, color: Theme.of(context).textTheme.bodyLarge!.color),
      )
    ];
  }

  @override
  String get searchFieldLabel => 'Search Notes'; // Set the hint text here

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => Get.back(),
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
        color: Theme.of(context).textTheme.bodyLarge!.color,
      ),
    );
  }

  List<Note> _filter(String q) => q.isEmpty
      ? controller.notes
      : controller.notes
          .where((p) => QuillHelper.convertStringDocumentToString(p.content!)
              .toLowerCase()
              .contains(q.toLowerCase()))
          .toList();

  Widget _grid(BuildContext context, List<Note> notes) {
    if (notes.isEmpty) {
      return Center(
        child: Text(
          'No notes found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    final layoutIndex = controller.layoutIndex;

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

  @override
  Widget buildSuggestions(BuildContext context) => _grid(context, _filter(query));

  @override
  Widget buildResults(BuildContext context) => _grid(context, _filter(query));
}
