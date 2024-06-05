import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes_app/controller/note_controller.dart';
import 'package:notes_app/helper/date_converter.dart';
import 'package:notes_app/helper/quill_helper.dart';
import 'package:notes_app/model/note_model.dart';
import 'package:notes_app/routing/app_routes.dart';
import 'package:notes_app/utils/font_size.dart';
import 'package:notes_app/utils/padding_size.dart';
import 'package:notes_app/utils/radius_size.dart';
import 'package:notes_app/utils/style.dart';
import 'package:notes_app/widgets/alert_dialog.dart';

class NoteCart extends StatelessWidget {
  final Note note;
  final int index;
  const NoteCart({super.key, required this.note, required this.index});

  @override
  Widget build(BuildContext context) {

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoute.getNoteDetailsPage(note)),
      onLongPress: () {
        showDialog(context: context, builder: (context) {
          return AlertDialogWidget(
            headingText: "Are you sure you want to delete this note?",
            contentText: "This will delete the note permanently. You cannot undo this action.",
            confirmFunction: () {
              Get.find<NoteController>().deleteNote(note.id!);
              Get.back();
            },
            declineFunction: () {
              Get.back();
            },
          );
        });
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              // color: '#2DCE29'.toColor(),
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(RadiusSize.large),
              boxShadow: [BoxShadow(color: Colors.grey[200]!, blurRadius: 10, offset: const Offset(2, 4))]
            ),
            padding: const EdgeInsets.all(PaddingSize.medium),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const SizedBox(height: PaddingSize.small),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      String value = QuillHelper.convertStringDocumentToString(note.content!);
                      value = smallSentence(value);
                      return Text(
                        value,
                        style: fontStyleNormal.copyWith(fontSize: FontSize.small),
                        overflow: TextOverflow.ellipsis,
                      );
                    }
                  ),
                ),
                const SizedBox(height: PaddingSize.small),

                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(
                    child: Text(
                      DateConverter.dateTimeStringToDateOnly(note.dateTimeEdited!),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: fontStyleMedium.copyWith(fontSize: FontSize.small),
                    ),
                  ),

                  // _createActions(context, note),
                ]),
              ],
            ),
          ),

          Positioned(
            right: 5, top: 10,
            child: InkWell(
              onTap: () => Get.find<NoteController>().favoriteNote(note.id!),
              child: Icon(note.isFavorite == 1 ? Icons.bookmark_rounded : Icons.bookmark_border_outlined),
            ),
          ),

          Positioned(
            right: 0, bottom: 5,
            child: _createActions(context, note),
          ),
        ],
      ),
    );
  }

  PopupMenuButton _createActions(BuildContext context, Note note) {
    return PopupMenuButton(
      elevation: 6,
      padding: EdgeInsets.zero,
      onSelected: (value) async {
        switch (value) {
          case 0:
            Get.toNamed(AppRoute.getEditNotePage(note));
            break;
          case 1:
            _deleteNote(context, note.id!);
            break;
          case 2:
            Get.find<NoteController>().shareNote(note.title!, note.content!);
            break;
          default:
            break;
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 0,
          child: Text("Edit Note", style: fontStyleNormal),
        ),
        PopupMenuItem(
          value: 1,
          child: Text("Delete Note", style: fontStyleNormal),
        ),
        PopupMenuItem(
          value: 2,
          child: Text("Share Note", style: fontStyleNormal),
        )
      ],
    );
  }

  void _deleteNote(BuildContext context, int id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialogWidget(
          headingText: "Are you sure you want to delete this note?",
          contentText: "This will delete the note permanently. You cannot undo this action.",
          confirmFunction: () {
            Get.find<NoteController>().deleteNote(id);
            Get.offAllNamed(AppRoute.HOME);
          },
          declineFunction: () => Get.back(),
        );
      },
    );
  }

  String smallSentence(String bigSentence){
    if(bigSentence.length > 100){
      return '${bigSentence.substring(0,100)}...';
    }
    else{
      return bigSentence;
    }
  }
}
