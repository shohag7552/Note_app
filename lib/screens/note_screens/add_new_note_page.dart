import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:get/get.dart';
import 'package:notes_app/utils/colors.dart';
import 'package:notes_app/utils/font_size.dart';
import 'package:notes_app/utils/padding_size.dart';
import 'package:notes_app/utils/style.dart';
import 'package:notes_app/widgets/text_edit_widget.dart';
import 'package:notes_app/widgets/toast.dart';

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
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.done),
            //     onPressed: () {
            //
            //       // print('===result is: ${_controller.document.toPlainText()}');
            //       final json = jsonEncode(_controller.document.toDelta().toJson());
            //       // print('===result is: ${_controller.document.toPlainText()}');
            //       // if (controller.titleController.text.isEmpty) {
            //       //   showToast(message: "Note title is empty");
            //       // } else if (controller.contentController.text.isEmpty) {
            //       //   showToast(message: "Note description is empty");
            //       // } else {
            //       //   controller.addNoteToDatabase(AppColor.greenColor.replaceAll('Color(0xFF', '#').replaceAll(")", ''));
            //       // }
            //     },
            //   ),
            // ],
          ),
          body: const TextEditWidget(readOnly: false, content: null, isAddNote: true),
          // body: Column(children: [
          //
          //   Expanded(
          //     child: Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 20.0),
          //       child: QuillProvider(
          //         configurations: QuillConfigurations(
          //           controller: _controller,
          //           sharedConfigurations: const QuillSharedConfigurations(
          //             locale: Locale('en'),
          //           ),
          //         ),
          //         child: Column(
          //           children: [
          //             Expanded(
          //               child: QuillEditor.basic(
          //                 configurations: const QuillEditorConfigurations(
          //                   readOnly: false,
          //                 ),
          //               ),
          //             ),
          //
          //             SafeArea(
          //               child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          //                 const QuillToolbar(
          //                   configurations: QuillToolbarConfigurations(
          //                     multiRowsDisplay: true,
          //                     showDirection: false,
          //                     showFontFamily: false,
          //                     showDividers: false,
          //                     showHeaderStyle: false,
          //                     showIndent: false,
          //                     showInlineCode: false,
          //                     showJustifyAlignment: false,
          //                     showQuote: false,
          //                     showSearchButton: false,
          //                     showRightAlignment: false,
          //                     showAlignmentButtons: false,
          //                     showLeftAlignment: false,
          //                     showStrikeThrough: false,
          //                     showSubscript: false,
          //                     showSuperscript: false,
          //                     showSmallButton: false,
          //                     showClearFormat: false,
          //                     showBackgroundColorButton: false,
          //                     showCodeBlock: false,
          //                     showRedo: false,
          //                     showUndo: false,
          //                     showItalicButton: false,
          //                     showUnderLineButton: false,
          //                     showLink: false,
          //                     showCenterAlignment: false,
          //                     showFontSize: false,
          //                   ),
          //                 ),
          //
          //                 IconButton(
          //                   icon: const Icon(Icons.check),
          //                   onPressed: (){
          //                     print('===result is: ${_controller.document.toPlainText()}');
          //                     final json = jsonEncode(_controller.document.toDelta().toJson());
          //                     print(
          //                       jsonEncode(_controller.document.toDelta().toJson()),
          //                     );
          //
          //                     Get.find<NoteController>().titleController.text = "test";
          //                     Get.find<NoteController>().contentController.text = json;
          //                     controller.addNoteToDatabase('');
          //                   },
          //                 ),
          //               ]),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          //
          //   // Expanded(
          //   //   child: SingleChildScrollView(
          //   //     child: Container(
          //   //       padding: const EdgeInsets.only(top: PaddingSize.medium, left: PaddingSize.medium, right: PaddingSize.medium),
          //   //       child: Column(children: [
          //   //           TextField(
          //   //             controller: controller.titleController,
          //   //             style: fontStyleBold.copyWith(fontSize: FontSize.large),
          //   //             cursorColor: Colors.black,
          //   //             decoration: InputDecoration(
          //   //               hintText: "Title",
          //   //               hintStyle: fontStyleBold.copyWith(color: Theme.of(context).hintColor, fontSize: FontSize.large),
          //   //               border: InputBorder.none,
          //   //             ),
          //   //             autofocus: true,
          //   //             onSubmitted: (text) => FocusScope.of(context).requestFocus(contentFocus),
          //   //           ),
          //   //
          //   //         SizedBox(
          //   //           height: 200,
          //   //           child: QuillProvider(
          //   //             configurations: QuillConfigurations(
          //   //               controller: _controller,
          //   //               sharedConfigurations: const QuillSharedConfigurations(
          //   //                 locale: Locale('en'),
          //   //               ),
          //   //             ),
          //   //             child: Column(
          //   //               children: [
          //   //                 const QuillToolbar(),
          //   //                 Expanded(
          //   //                   child: QuillEditor.basic(
          //   //                     configurations: const QuillEditorConfigurations(
          //   //                       readOnly: false,
          //   //                     ),
          //   //                   ),
          //   //                 )
          //   //               ],
          //   //             ),
          //   //           ),
          //   //         ),
          //   //
          //   //         // QuillEditor.basic(
          //   //         //   configurations: QuillEditorConfigurations(
          //   //         //     controller: _controller,
          //   //         //   ), // true for view only mode
          //   //         // ),
          //   //
          //   //           TextField(
          //   //             style: fontStyleNormal.copyWith(fontSize: FontSize.mediumLarge),
          //   //             controller: controller.contentController,
          //   //             focusNode: contentFocus,
          //   //             decoration: InputDecoration(
          //   //               hintText: "Type note here...",
          //   //               hintStyle: fontStyleNormal.copyWith(fontSize: FontSize.large),
          //   //               border: InputBorder.none,
          //   //             ),
          //   //             cursorColor: Colors.black,
          //   //             keyboardType: TextInputType.multiline,
          //   //             maxLines: 15,
          //   //             // expands: true,
          //   //           ),
          //   //         ],
          //   //       ),
          //   //     ),
          //   //   ),
          //   // ),
          //
          //   // SafeArea(
          //   //   child: InkWell(
          //   //     onTap: () {
          //   //       print('====> ${AppColor.greenColor.replaceAll('Color(0x', '#').replaceAll(")", '')}');
          //   //     },
          //   //     child: Container(
          //   //       height: 30, width: 30,
          //   //       decoration: const BoxDecoration(
          //   //         shape: BoxShape.circle,
          //   //         color: Colors.green,
          //   //         // color: AppColor.greenColor.toColor(),
          //   //       ),
          //   //     ),
          //   //   ),
          //   // )
          // ]),
          // floatingActionButton: FloatingActionButton.extended(
          //   onPressed: () {
          //     if (controller.titleController.text.isEmpty) {
          //       showToast(message: "Note title is empty");
          //     } else if (controller.contentController.text.isEmpty) {
          //       showToast(message: "Note description is empty");
          //     } else {
          //       controller.addNoteToDatabase();
          //     }
          //   },
          //   label: Text(
          //     "Save Note",
          //     textAlign: TextAlign.center,
          //     style: fontStyleMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color),
          //   ),
          //   icon: const Icon(Icons.save),
          //   // backgroundColor: AppColor.buttonColor,
          // ),
        );
      }
    );
  }
}