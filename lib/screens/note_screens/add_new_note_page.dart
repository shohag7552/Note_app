import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/widgets/text_edit_widget.dart';

import '../../controller/note_controller.dart';

class AddNewNotePage extends StatefulWidget {
  const AddNewNotePage({super.key});

  @override
  State<AddNewNotePage> createState() => _AddNewNotePageState();
}

class _AddNewNotePageState extends State<AddNewNotePage> {
  @override
  void initState() {
    super.initState();
    Get.find<NoteController>().titleController.text = '';
    Get.find<NoteController>().contentController.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GetBuilder<NoteController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: Text(
              'New note',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          body: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: TextEditWidget(readOnly: false, content: null, isAddNote: true),
              ),
            ],
          ),
        );
      },
    );
  }
}
