import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes_app/utils/font_size.dart';
import 'package:notes_app/utils/padding_size.dart';
import 'package:notes_app/utils/radius_size.dart';
import 'package:notes_app/utils/style.dart';
import '../controller/note_controller.dart';
import 'note_detail_page.dart';

class Search extends SearchDelegate {
  final NoteController controller = Get.find<NoteController>();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = "";
        },
        icon: const Icon(Icons.clear, color: Colors.black),
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
        color: Colors.black,
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? controller.notes
        : controller.notes.where(
            (p) {
              return p.title!.toLowerCase().contains(query.toLowerCase()) ||
                  p.content!.toLowerCase().contains(query.toLowerCase());
            },
          ).toList();
    return Container(
      padding: const EdgeInsets.only(top: PaddingSize.small, right: PaddingSize.small, left: PaddingSize.small),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestionList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => Get.to(const NoteDetailPage(), arguments: index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor,
                  borderRadius: BorderRadius.circular(RadiusSize.medium),
                ),
                padding: const EdgeInsets.all(PaddingSize.medium),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.notes[index].title!,
                      style: fontStyleBold.copyWith(fontSize: FontSize.mediumLarge),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: PaddingSize.small),

                    Text(
                      suggestionList[index].content!,
                      style: fontStyleNormal.copyWith(fontSize: FontSize.extraMedium),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: PaddingSize.small),

                    Text(controller.notes[index].dateTimeEdited!),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    throw UnimplementedError();
  }
}
