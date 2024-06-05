import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes_app/helper/date_converter.dart';
import 'package:notes_app/helper/quill_helper.dart';
import 'package:notes_app/routing/app_routes.dart';
import 'package:notes_app/utils/font_size.dart';
import 'package:notes_app/utils/padding_size.dart';
import 'package:notes_app/utils/radius_size.dart';
import 'package:notes_app/utils/style.dart';
import '../controller/note_controller.dart';

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
        : controller.notes.where((p) {
              return /*p.title!.toLowerCase().contains(query.toLowerCase()) ||*/
                  QuillHelper.convertStringDocumentToString(p.content!).toLowerCase().contains(query.toLowerCase());
              },
          ).toList();
    return ListView.builder(
      shrinkWrap: true,
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return Material(
          child: InkWell(
            onTap: () => Get.toNamed(AppRoute.getNoteDetailsPage(suggestionList[index])),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(RadiusSize.medium),
                boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10, offset: const Offset(0, 0))],
              ),
              padding: const EdgeInsets.all(PaddingSize.medium),
              margin: const EdgeInsets.symmetric(horizontal: PaddingSize.medium, vertical: PaddingSize.extraSmall),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   controller.notes[index].title!,
                  //   style: fontStyleBold.copyWith(fontSize: FontSize.mediumLarge),
                  //   maxLines: 1, overflow: TextOverflow.ellipsis,
                  // ),
                  // const SizedBox(height: PaddingSize.small),

                  Text(
                    QuillHelper.convertStringDocumentToString(suggestionList[index].content!),
                    style: fontStyleNormal.copyWith(fontSize: FontSize.extraMedium),
                    maxLines: 5, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: PaddingSize.small),

                  Align(alignment: Alignment.bottomRight, child: Text(DateConverter.dateTimeStringToDateOnly(controller.notes[index].dateTimeEdited!))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    throw UnimplementedError();
  }
}
