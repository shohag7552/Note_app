import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/widgets/text_edit_widget.dart';

import '../../controller/note_controller.dart';

class EditNotePage extends StatefulWidget {
  final Note note;
  const EditNotePage({super.key, required this.note});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  double bgOpacity = 0.1;

  @override
  void initState() {
    super.initState();
    Get.find<NoteController>().titleController.text = widget.note.title!;
    Get.find<NoteController>().contentController.text = widget.note.content!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Edit note',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          const SizedBox(width: 4),
        ],
      ),
      body: GetBuilder<BackgroundController>(
        builder: (_) {
          return TextEditWidget(
            readOnly: false,
            content: Document.fromJson(jsonDecode(widget.note.content!)),
            isAddNote: false,
            note: widget.note,
          );
        },
      ),
    );
  }
}
