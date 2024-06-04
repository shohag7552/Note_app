import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:notes_app/model/note_model.dart';
import 'package:notes_app/utils/style.dart';
import 'package:notes_app/widgets/text_edit_widget.dart';

import '../controller/note_controller.dart';

class EditNotePage extends StatefulWidget {
  final Note note;
  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  // final NoteController controller = Get.find();

  @override
  void initState() {
    super.initState();

    Get.find<NoteController>().titleController.text = widget.note.title!;
    Get.find<NoteController>().contentController.text = widget.note.content!;
  }

  @override
  Widget build(BuildContext context) {
    // final int i = ModalRoute.of(context)?.settings.arguments as int;
    // controller.titleController.text = controller.notes[i].title!;
    // controller.contentController.text = controller.notes[i].content!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          "Edit Note",
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: TextEditWidget(readOnly: false, content: Document.fromJson(jsonDecode(widget.note.content!)), isAddNote: false, note: widget.note),
      /*body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
          ),
          child: Column(
            children: [
              TextField(
                controller: Get.find<NoteController>().titleController,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
                cursorColor: Colors.black,
                enableInteractiveSelection: false,
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 1,
                  ),
                  border: InputBorder.none,
                ),
              ),
              TextField(
                style: const TextStyle(
                  fontSize: 22,
                ),
                cursorColor: Colors.black,
                enableInteractiveSelection: false,
                controller: Get.find<NoteController>().contentController,
                decoration: const InputDecoration(
                  hintText: "Content",
                  hintStyle: TextStyle(
                    fontSize: 17,
                  ),
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.multiline,
                maxLines: null,
                autofocus: true,
              ),
            ],
          ),
        ),
      ),*/
      /*floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.find<NoteController>().updateNote(widget.note.id!, widget.note.dateTimeCreated!, widget.note.isFavorite??0);
        },
        label: Text(
          "Save Note",
          textAlign: TextAlign.center,
          style: fontStyleMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
        ),
        icon: const Icon(Icons.save),
        // backgroundColor: AppColor.buttonColor,
      ),*/
    );
  }
}
