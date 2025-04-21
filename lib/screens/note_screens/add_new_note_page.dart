
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/utils/style.dart';
import 'package:my_note_app/widgets/text_edit_widget.dart';

import '../../controller/note_controller.dart';

class AddNewNotePage extends StatefulWidget {
  const AddNewNotePage({super.key});

  @override
  State<AddNewNotePage> createState() => _AddNewNotePageState();
}

class _AddNewNotePageState extends State<AddNewNotePage> {
  // final NoteController controller = Get.find();

  // final FocusNode contentFocus = FocusNode();
  // QuillController _controller = QuillController.basic();

  @override
  void initState() {
    super.initState();

    Get.find<NoteController>().titleController.text = "";
    Get.find<NoteController>().contentController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoteController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Add New Note", style: fontStyleNormal),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
          ),
          body: const TextEditWidget(readOnly: false, content: null, isAddNote: true),
        );
      }
    );
  }
}