import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/utils/padding_size.dart';

class TextEditWidget extends StatefulWidget {
  final bool readOnly;
  final Document? content;
  final bool isAddNote;
  final Note? note;
  const TextEditWidget({super.key, required this.readOnly, required this.content, required this.isAddNote, this.note});

  @override
  State<TextEditWidget> createState() => _TextEditWidgetState();
}

class _TextEditWidgetState extends State<TextEditWidget> {

  final QuillController controller = QuillController.basic();
  @override
  void initState() {
    super.initState();

    controller.readOnly = widget.readOnly;
    controller.document = widget.content != null ? widget.content! : controller.document;

    // controller.formatTextStyle(index, len, style)
    // controller.formatText(
    //   0,
    //   controller.document.length,
    //   Attribute.color.withValue('FFFFFF'), // Hex color for white
    // );
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PaddingSize.medium),
      child: Column(children: [

        Expanded(
          child: QuillEditor.basic(
            controller: controller,
            config: QuillEditorConfig(
              customStyles: Get.find<BackgroundController>().backgroundImage != null ? DefaultStyles(
                  paragraph: DefaultTextBlockStyle(
                    TextStyle(
                      color: Colors.white, // Set default text color to white
                      fontSize: 16, // You can also set other default styles here
                    ),
                    HorizontalSpacing(0, 0), // Default line spacing
                    VerticalSpacing(0, 0),
                    VerticalSpacing(0,0), // No text decoration
                    BoxDecoration(color: Colors.white),
                  )) : null,
            ),
          ),
        ),

        SafeArea(
          child: !widget.readOnly ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

            Expanded(
              child: QuillSimpleToolbar(
                controller: controller,
                config: QuillSimpleToolbarConfig(
                  color: Colors.transparent,
                  // iconTheme: QuillIconTheme(iconButtonUnselectedData: IconButtonData(color: Colors.white, disabledColor: Colors.lightGreenAccent, focusColor: Colors.white, highlightColor: Colors.white), iconButtonSelectedData: ),
                  multiRowsDisplay: false,
                  showDirection: false,
                  showFontFamily: false,
                  showDividers: false,
                  showHeaderStyle: false,
                  showIndent: false,
                  showInlineCode: false,
                  showJustifyAlignment: false,
                  showQuote: false,
                  showSearchButton: false,
                  showRightAlignment: false,
                  showAlignmentButtons: false,
                  showLeftAlignment: false,
                  showStrikeThrough: false,
                  showSubscript: false,
                  showSuperscript: false,
                  showSmallButton: false,
                  showClearFormat: false,
                  showBackgroundColorButton: false,
                  showCodeBlock: false,
                  showRedo: false,
                  showUndo: false,
                  showItalicButton: false,
                  showUnderLineButton: false,
                  showLink: false,
                  showCenterAlignment: false,
                  showFontSize: false,
                  showClipboardCut: false,
                  showClipboardCopy: false,
                  showClipboardPaste: false,
                ),
              ),
            ),

            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                final json = jsonEncode(controller.document.toDelta().toJson());

                if(widget.isAddNote) {
                  Get.find<NoteController>().addNoteToDatabase(
                    title: 'This is title',
                    content: json, color: '#FFA0A4A8',
                  );
                } else {
                  Get.find<NoteController>().updateNote(
                      Note(
                        id: widget.note!.id,
                        title: widget.note!.title,
                        content: json,
                        dateTimeEdited: DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now()),
                        dateTimeCreated: widget.note!.dateTimeCreated,
                        isFavorite: widget.note!.isFavorite??0,
                        color: widget.note!.color,
                      )
                  );

                }
              },
            ),
          ]) : const SizedBox(),
        ),

      ]),
    );
  }
}
