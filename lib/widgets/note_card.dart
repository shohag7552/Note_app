import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:notes_app/controller/note_controller.dart';
import 'package:notes_app/helper/color_extension.dart';
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
      onTap: () => Get.toNamed(AppRoute.NOTE_DETAILS, arguments: index),
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
            Row(children: [
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

            Expanded(
              child: Text(
                note.content!,
                style: fontStyleNormal.copyWith(fontSize: FontSize.small),
                overflow: TextOverflow.ellipsis, maxLines: 4,
              ),
            ),
            const SizedBox(height: PaddingSize.small),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(
                child: Text(
                  note.dateTimeEdited!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: fontStyleNormal.copyWith(fontSize: FontSize.small),
                ),
              ),

              const Icon(Icons.more_horiz),
            ]),

            // Text(
            //   controller.notes[index].color??'',
            //   style: fontStyleNormal.copyWith(fontSize: FontSize.small),
            // ),
          ],
        ),
      ),
    );
  }
}
