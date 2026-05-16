import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/helper/color_extension.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/utils/padding_size.dart';
import 'package:my_note_app/widgets/color_picker_sheet.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:my_note_app/widgets/custom_image_embed.dart';

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

  final GlobalKey _editorKey = GlobalKey();
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

  RenderObject? _findRenderEditor(RenderObject? root) {
    if (root == null) return null;
    if (root.runtimeType.toString() == 'RenderEditor') return root;
    RenderObject? result;
    root.visitChildren((child) {
      result ??= _findRenderEditor(child);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PaddingSize.medium),
      child: Column(children: [

        Expanded(
          child: DragTarget<String>(
            onAcceptWithDetails: (details) {
              try {
                final data = jsonDecode(details.data);
                final path = data['path'];
                final width = data['w'];
                
                final RenderObject? rootRender = _editorKey.currentContext?.findRenderObject();
                dynamic renderEditor = _findRenderEditor(rootRender);
                
                if (renderEditor != null) {
                  final localOffset = renderEditor.globalToLocal(details.offset);
                  final position = renderEditor.getPositionForOffset(localOffset);
                  
                  final index = position.offset;
                  final embed = BlockEmbed.image('$path?w=$width');
                  
                  controller.replaceText(index, 0, embed, null);
                  controller.replaceText(index + 1, 0, '\n', null);
                  
                  controller.updateSelection(
                    TextSelection.collapsed(offset: index + 1),
                    ChangeSource.local,
                  );
                }
              } catch (e) {
                // Ignore
              }
            },
            builder: (context, candidateData, rejectedData) {
              return QuillEditor.basic(
                key: _editorKey,
                controller: controller,
                config: QuillEditorConfig(
                  embedBuilders: [
                    CustomImageEmbedBuilder(),
                  ],
                ),
              );
            },
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

            // Image picker button
            IconButton(
              tooltip: 'Add Image',
              onPressed: () async {
                // Save selection before focus is lost to the image picker
                int index = controller.selection.baseOffset;
                int length = controller.selection.extentOffset - index;
                
                if (index < 0) {
                  index = controller.document.length - 1;
                  if (index < 0) index = 0;
                  length = 0;
                } else if (length < 0) {
                  index = controller.selection.extentOffset;
                  length = controller.selection.baseOffset - index;
                }

                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null && mounted) {
                  final croppedFile = await ImageCropper().cropImage(
                    sourcePath: image.path,
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: 'Crop Image',
                        toolbarColor: theme.colorScheme.primary,
                        toolbarWidgetColor: theme.colorScheme.onPrimary,
                        initAspectRatio: CropAspectRatioPreset.original,
                        lockAspectRatio: false,
                      ),
                      IOSUiSettings(
                        title: 'Crop Image',
                      ),
                    ],
                  );
                  if (croppedFile != null) {
                    controller.replaceText(
                      index,
                      length,
                      BlockEmbed.image('${croppedFile.path}?w=300'),
                      null,
                    );
                    
                    // Move cursor past the inserted image
                    controller.updateSelection(
                      TextSelection.collapsed(offset: index + 1),
                      ChangeSource.local,
                    );
                  }
                }
              },
              icon: Icon(Icons.image_outlined, color: theme.iconTheme.color),
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
