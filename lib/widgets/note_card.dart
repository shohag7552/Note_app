import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:notes_app/controller/note_controller.dart';
import 'package:notes_app/helper/date_converter.dart';
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
    final QuillController controller = QuillController.basic();
    controller.document = Document.fromJson(jsonDecode(note.content!));

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
      child: Container(
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
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                child: Text(
                  note.title!,
                  style: fontStyleMedium.copyWith(fontSize: FontSize.extraMedium),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ),

              InkWell(
                onTap: () => Get.find<NoteController>().favoriteNote(note.id!),
                child: Icon(note.isFavorite == 1 ? Icons.bookmark_rounded : Icons.bookmark_border_outlined),
              ),
            ]),
            const SizedBox(height: PaddingSize.small),

            // Expanded(
            //   child: Text(
            //     note.content!,
            //     style: fontStyleNormal.copyWith(fontSize: FontSize.small),
            //     overflow: TextOverflow.ellipsis, maxLines: 4,
            //   ),
            // ),
            QuillProvider(
              configurations: QuillConfigurations(
                controller: controller,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
              ),
              child: Expanded(
                child: QuillEditor.basic(
                  configurations: const QuillEditorConfigurations(
                    readOnly: true,
                    // scrollable: false,
                    showCursor: false,
                    expands: true,
                    maxHeight: 100,
                    minHeight: 50,

                  ),
                ),
              ),
            ),
            const SizedBox(height: PaddingSize.small),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                child: Text(
                  // note.dateTimeEdited!,
                  DateConverter.dateTimeStringToDateOnly(note.dateTimeEdited!),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: fontStyleNormal.copyWith(fontSize: FontSize.small),
                ),
              ),

              _createActions(context, note),
            ]),
          ],
        ),
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
}
