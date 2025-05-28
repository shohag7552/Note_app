
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/utils/style.dart';
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
  // final NoteController controller = Get.find();

  // final FocusNode contentFocus = FocusNode();
  // QuillController _controller = QuillController.basic();
  SpeechToText _speechToText = SpeechToText();
  String _lastWord = '';

  @override
  void initState() {
    super.initState();

    Get.find<NoteController>().titleController.text = "";
    Get.find<NoteController>().contentController.text = "";
  }

  Future<void> voiceAction() async {
    bool available = await _speechToText.initialize(
      onStatus: (value) {
        print('====onStatus= $value');
        },
      onError: (v) {
        print('===errpr: $v');
      }
    );
    if ( available ) {
      _speechToText.listen( onResult: _resultListener );
    }
    else {
      print("The user has denied the use of speech recognition.");
    }
    // some time later...
    // _speechToText.stop();
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _resultListener(SpeechRecognitionResult result) {
    setState(() {
      _lastWord = result.recognizedWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoteController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Add New Note", style: fontStyleNormal),
            backgroundColor: Theme.of(context).cardColor,
          ),
          body: Column(
            spacing: 20,
            children: [
              Text(_lastWord),

              Expanded(child: const TextEditWidget(readOnly: false, content: null, isAddNote: true)),
            ],
          ),
          // floatingActionButton: FloatingActionButton(
          //   onPressed: () {
          //     // voiceAction();
          //     _speechToText.isNotListening ? voiceAction() : _stopListening();
          //   },
          //   child: Icon(_speechToText.isNotListening ? Icons.mic_off : Icons.mic),
          // ),
        );
      }
    );
  }
}