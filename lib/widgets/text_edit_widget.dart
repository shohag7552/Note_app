import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/helper/color_extension.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/utils/padding_size.dart';
import 'package:my_note_app/widgets/color_picker_sheet.dart';

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
  late String _selectedColor;

  @override
  void initState() {
    super.initState();
    controller.readOnly = widget.readOnly;
    controller.document = widget.content != null ? widget.content! : controller.document;
    _selectedColor = widget.note?.color ?? '#FFA0A4A8';
  }

  void _showColorPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ColorPickerSheet(
        currentColor: _selectedColor,
        onSelected: (hex) => setState(() => _selectedColor = hex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PaddingSize.medium),
      child: Column(children: [

        Expanded(
          child: QuillEditor.basic(
            controller: controller,
            config: const QuillEditorConfig(),
          ),
        ),

        SafeArea(
          child: !widget.readOnly ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

            Expanded(
              child: QuillSimpleToolbar(
                controller: controller,
                config: QuillSimpleToolbarConfig(
                  color: Colors.transparent,
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

            // Color picker button
            IconButton(
              tooltip: 'Card color',
              onPressed: () => _showColorPicker(context),
              icon: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.palette_outlined, color: theme.iconTheme.color),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _selectedColor.toColor() as Color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () async {
                final json = jsonEncode(controller.document.toDelta().toJson());

                if(widget.isAddNote) {
                  final (title, _) = QuillHelper.deriveTitleAndBody(json);
                  Get.find<NoteController>().addNoteToDatabase(
                    title: title,
                    content: json,
                    color: _selectedColor,
                  );
                } else {
                  Get.find<NoteController>().updateNote(
                    Note(
                      id: widget.note!.id,
                      title: widget.note!.title,
                      content: json,
                      dateTimeEdited: DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now()),
                      dateTimeCreated: widget.note!.dateTimeCreated,
                      isFavorite: widget.note!.isFavorite ?? 0,
                      color: _selectedColor,
                    ),
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
