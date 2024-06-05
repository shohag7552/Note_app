import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:notes_app/model/note_model.dart';
import 'package:notes_app/routing/app_routes.dart';
import 'package:notes_app/utils/font_size.dart';
import 'package:notes_app/utils/padding_size.dart';
import 'package:notes_app/utils/style.dart';
import 'package:notes_app/widgets/text_edit_widget.dart';

import '../controller/note_controller.dart';
import '../widgets/alert_dialog.dart';

class NoteDetailPage extends StatefulWidget {
  final Note note;
  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  // final NoteController controller = Get.find();
  // final json = jsonDecode(r'{"insert":"hello\n"}');

  // _controller.document = Document.fromJson(json);

  @override
  Widget build(BuildContext context) {
    // final int i = ModalRoute.of(context)?.settings.arguments as int;
    // print('=======index is : $i'); final doc = Document.fromDelta(DeltaHtmlExt.fromHtml(widget.inputText));
    // print('====s>>> ${Document.fromJson(jsonDecode(widget.note.content!))}');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Note Details", style: fontStyleNormal),
        actions: [
          PopupMenuButton(
            onSelected: (val) {
              if (val == 0) {
                Get.toNamed(AppRoute.getEditNotePage(widget.note));
              } else if (val == 1) {
                deleteNote(context, widget.note.id!);
              } else if (val == 2) {
                Get.find<NoteController>().shareNote(widget.note.title!, widget.note.content!);
              }
            },
            itemBuilder: (BuildContext bc) {
              return const [
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
              ];
            },
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: TextEditWidget(readOnly: true, content: Document.fromJson(jsonDecode(widget.note.content!)), isAddNote: true),

      floatingActionButton: FloatingActionButton(
        elevation: 6,
        onPressed: () => Get.toNamed(AppRoute.getEditNotePage(widget.note)),
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
        child: Icon(Icons.edit, color: Theme.of(context).cardColor),
      ),
      /*body: GetBuilder<NoteController>(
        builder: (controller) => Scrollbar(
          child: Container(
            padding: const EdgeInsets.only(top: PaddingSize.medium, left: PaddingSize.medium, right: PaddingSize.medium),
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: PaddingSize.small),

                SelectableText(
                  widget.note.title!,
                  style: fontStyleExtraLarge.copyWith(fontSize: FontSize.large),
                ),
                const SizedBox(height: PaddingSize.medium),

                Text(
                  "Last Edited : ${widget.note.dateTimeEdited}",
                  style: fontStyleBold.copyWith(fontSize: FontSize.medium),
                ),
                const SizedBox(height: PaddingSize.medium),

                SelectableText(
                  widget.note.content!,
                  style: fontStyleNormal.copyWith(fontSize: FontSize.mediumLarge),
                ),

                const SizedBox(height: PaddingSize.small),
              ]),
            ),
          ),
        ),
      ),*/
    );
  }

  void deleteNote(BuildContext context, int id) async {
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

  void shareNote(String title, String content) async {
    Get.find<NoteController>().shareNote( title, content);
  }
}
