import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/helper/color_extension.dart';
import 'package:my_note_app/helper/note_image_helper.dart';
import 'package:my_note_app/helper/quill_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/utils/padding_size.dart';
import 'package:my_note_app/widgets/color_picker_sheet.dart';
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

class _TextEditWidgetState extends State<TextEditWidget> with WidgetsBindingObserver {

  final GlobalKey _editorKey = GlobalKey();
  final QuillController controller = QuillController.basic();
  late String _selectedColor;

  // What the database holds, so only real changes are saved.
  late String _savedContent;
  late String _savedColor;
  int? _noteId;
  String? _createdAt;
  bool _savedThisSession = false;
  // Saves run one at a time, so a new note can't be inserted twice.
  Future<bool> _lastSave = Future.value(true);

  @override
  void initState() {
    super.initState();
    controller.readOnly = widget.readOnly;
    controller.document = widget.content != null ? widget.content! : controller.document;
    _selectedColor = widget.note?.color ?? '#FFA0A4A8';
    _savedContent = _currentContent();
    _savedColor = _selectedColor;
    _noteId = widget.note?.id;
    _createdAt = widget.note?.dateTimeCreated;
    if (!widget.readOnly) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // inactive comes first when the app is swiped away from recents.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _save();
    }
  }

  String _currentContent() => jsonEncode(controller.document.toDelta().toJson());

  Future<bool> _save() => _lastSave = _lastSave.then((_) => _saveIfChanged());

  /// Returns false only if the changes could not be stored.
  Future<bool> _saveIfChanged() async {
    final content = _currentContent();
    final color = _selectedColor;
    if (content == _savedContent && color == _savedColor) return true;
    if (_noteId == null && controller.document.isEmpty()) return true;

    final now = DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now());
    final (title, _) = QuillHelper.deriveTitleAndBody(content);
    final note = Note(
      id: _noteId,
      title: title,
      content: content,
      dateTimeEdited: now,
      dateTimeCreated: _createdAt ?? now,
      isFavorite: widget.note?.isFavorite ?? 0,
      color: color,
      syncStatus: 'pending',
    );
    try {
      await Get.find<NoteController>().saveNote(note);
    } catch (e) {
      print('[TextEditWidget] Save failed: $e');
      return false;
    }
    _noteId = note.id;
    _createdAt = note.dateTimeCreated;
    _savedContent = content;
    _savedColor = color;
    _savedThisSession = true;
    return true;
  }

  /// Stays on the screen if saving failed, so the text isn't lost.
  Future<bool> _saveBeforeLeaving() async {
    if (await _save()) return true;
    Get.snackbar('Note not saved', 'Could not save this note. Please try again.',
        snackPosition: SnackPosition.BOTTOM);
    return false;
  }

  Future<void> _onBack() async {
    if (!await _saveBeforeLeaving() || !mounted) return;
    // The note detail page underneath still shows the old content after a save.
    if (_savedThisSession) {
      Get.offAllNamed(AppRoute.HOME);
    } else {
      Navigator.of(context).pop();
    }
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

    return PopScope(
      canPop: widget.readOnly,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: PaddingSize.medium),
      child: Column(children: [

        Expanded(
          child: DragTarget<String>(
            onAcceptWithDetails: (details) {
              try {
                final data = jsonDecode(details.data);
                final path = data['path'];
                final width = data['w'];
                final dx = data['dx'] ?? 0.0;
                final dy = data['dy'] ?? 0.0;
                
                final RenderObject? rootRender = _editorKey.currentContext?.findRenderObject();
                dynamic renderEditor = _findRenderEditor(rootRender);
                
                if (renderEditor != null) {
                  // Adjust offset by where the user was holding the image
                  final touchOffset = details.offset + Offset(dx, dy);
                  final localOffset = renderEditor.globalToLocal(touchOffset);
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
                  placeholder: widget.isAddNote ? 'Type here...' : null,
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
                final image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1600,
                  imageQuality: 80,
                );
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
                    final imagePath = await NoteImageHelper.importPicked(croppedFile.path);
                    controller.replaceText(
                      index,
                      length,
                      BlockEmbed.image('$imagePath?w=300'),
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
                if (await _saveBeforeLeaving()) Get.offAllNamed(AppRoute.HOME);
              },
            ),
          ]) : const SizedBox(),
        ),

      ]),
      ),
    );
  }
}
