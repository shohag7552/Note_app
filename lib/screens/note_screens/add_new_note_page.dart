import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/widgets/text_edit_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../controller/note_controller.dart';

class AddNewNotePage extends StatefulWidget {
  const AddNewNotePage({super.key});

  @override
  State<AddNewNotePage> createState() => _AddNewNotePageState();
}

class _AddNewNotePageState extends State<AddNewNotePage> {
  final SpeechToText _speechToText = SpeechToText();
  String _lastWord = '';

  @override
  void initState() {
    super.initState();
    Get.find<NoteController>().titleController.text = '';
    Get.find<NoteController>().contentController.text = '';
  }

  Future<void> voiceAction() async {
    bool available = await _speechToText.initialize(
      onStatus: (_) {},
      onError: (_) {},
    );
    if (available) {
      _speechToText.listen(onResult: _resultListener);
    }
  }

  void _resultListener(SpeechRecognitionResult result) {
    setState(() => _lastWord = result.recognizedWords);
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_lastWord.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Text(
                    _lastWord,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ),
              const Expanded(
                child: TextEditWidget(readOnly: false, content: null, isAddNote: true),
              ),
            ],
          ),
        );
      },
    );
  }
}
