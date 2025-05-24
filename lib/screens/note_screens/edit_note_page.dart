import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/widgets/background_color_opacity_dialog.dart';
import 'package:my_note_app/widgets/text_edit_widget.dart';

import '../../controller/note_controller.dart';

class EditNotePage extends StatefulWidget {
  final Note note;
  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  // final NoteController controller = Get.find();

  double bgOpacity = 0.1;

  @override
  void initState() {
    super.initState();

    Get.find<NoteController>().titleController.text = widget.note.title!;
    Get.find<NoteController>().contentController.text = widget.note.content!;
    bgOpacity = Get.find<BackgroundController>().getOpacity();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Make the AppBar transparent
        elevation: 0, //
        // backgroundColor: Theme.of(context).cardColor,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.bodyLarge!.color,
        ),
        title: const Text("Edit Note"),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          if(Get.find<BackgroundController>().backgroundImage != null)
          IconButton(
            onPressed: (){
              britenessWidget();
            },
            icon: Icon(Icons.brightness_4_outlined),
          ),

          IconButton(
            onPressed: () async {
              ///Take image from gallery...
              XFile? image = await Get.find<BackgroundController>().pickBackgroundImage();

              ///If successfully take image, then show background color opacity..
              if(image != null) {
                britenessWidget();
              }
              },
            icon: Icon(Icons.image_rounded),
          ),
        ],
      ),
      body: GetBuilder<BackgroundController>(
          builder: (backgroundController) {
            return Container(
              decoration: backgroundController.backgroundImage != null ? BoxDecoration(
                image: DecorationImage(image: FileImage(File(backgroundController.backgroundImage!.path)), fit: BoxFit.cover),
              ) : null,
              // padding: const EdgeInsets.only(top: 6),
              child: Container(
                color: backgroundController.backgroundImage != null ? Colors.black.withValues(alpha: bgOpacity) : null,
                child: TextEditWidget(readOnly: false, content: Document.fromJson(jsonDecode(widget.note.content!)), isAddNote: false, note: widget.note),
              ),
            );
          }
      ),
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

  void britenessWidget() {
    Get.dialog(BackgroundColorOpacityDialog(), barrierColor: Colors.transparent).then((v){
      setState(() {
        bgOpacity = v;
        Get.find<BackgroundController>().setOpacity(bgOpacity);
      });
    });
  }
}
