import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/widgets/note_card.dart';
import '../../controller/note_controller.dart';

class Search extends SearchDelegate {
  final NoteController controller = Get.find<NoteController>();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          if(query.isNotEmpty) {
            query = "";
          } else {
            Get.back();
          }
        },
        icon: Icon(Icons.clear, color:  Theme.of(context).textTheme.bodyLarge!.color),
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

  List _filter(String q) => q.isEmpty
      ? controller.notes
      : controller.notes
          .where((p) => QuillHelper.convertStringDocumentToString(p.content!)
              .toLowerCase()
              .contains(q.toLowerCase()))
          .toList();

  Widget _grid(BuildContext context, List notes) {
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        itemCount: notes.length,
        itemBuilder: (context, index) =>
            NoteCart(note: notes[index], index: index),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => _grid(context, _filter(query));

  @override
  Widget buildResults(BuildContext context) => _grid(context, _filter(query));
}
