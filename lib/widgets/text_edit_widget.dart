import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/controller/note_controller.dart';
import 'package:notes_app/model/note_model.dart';
import 'package:notes_app/utils/padding_size.dart';
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
  }

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PaddingSize.medium),
      child: Column(children: [

        Expanded(
          child: QuillEditor.basic(
            configurations: QuillEditorConfigurations(
              controller: controller,
              // readOnly: false,
              sharedConfigurations: const QuillSharedConfigurations(
                locale: Locale('en'),
              ),
              checkBoxReadOnly: true,
              // autoFocus: false,
              showCursor: !widget.readOnly,
            ),
          ),
        ),

        SafeArea(
          child: !widget.readOnly ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            QuillToolbar.simple(
              configurations: QuillSimpleToolbarConfigurations(
                controller: controller,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
                multiRowsDisplay: true,
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

        /*Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: QuillProvider(
              configurations: QuillConfigurations(
                controller: controller,
                sharedConfigurations: const QuillSharedConfigurations(
                  locale: Locale('en'),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: QuillEditor.basic(
                      configurations: QuillEditorConfigurations(
                        readOnly: widget.readOnly,
                        showCursor: !widget.readOnly,
                      ),
                    ),
                  ),

                  !widget.readOnly ? SafeArea(
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const QuillToolbar(
                        configurations: QuillToolbarConfigurations(
                          multiRowsDisplay: true,
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
                    ]),
                  ) : const SizedBox(),
                ],
              ),
            ),
          ),
        ),*/

      ]),
    );
  }
}
