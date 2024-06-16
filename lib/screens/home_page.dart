import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes_app/routing/app_routes.dart';
import 'package:notes_app/screens/auth_screen.dart';
import 'package:notes_app/screens/note_screens/search_screen.dart';
import 'package:notes_app/utils/font_size.dart';
import 'package:notes_app/utils/images.dart';
import 'package:notes_app/utils/padding_size.dart';
import 'package:notes_app/utils/style.dart';
import 'package:notes_app/widgets/note_card.dart';
import '../controller/note_controller.dart';
import '../widgets/alert_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoteController>(
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Notes", style: fontStyleLarge.copyWith(fontSize: FontSize.large)),
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  showSearch(context: context, delegate: Search());
                },
              ),
              PopupMenuButton(
                onSelected: (val) {
                  if (val == 0) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialogWidget(
                          headingText: "Are you sure you want to delete all notes?",
                          contentText: "This will delete all notes permanently. You cannot undo this action.",
                          confirmFunction: () {
                            controller.deleteAllNotes();
                            Get.back();
                          },
                          declineFunction: () {
                            Get.back();
                          },
                        );
                      },
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 0,
                    child: Text(
                      "Delete All Notes",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  )
                ],
              ),
            ],
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          body: GetBuilder<NoteController>(
            builder: (_) => controller.isEmpty() ? emptyNotes() : viewNotes(controller),
          ),
        );
      }
    );
  }

  Widget viewNotes(NoteController controller) {
    return Scrollbar(
      child: Container(
        padding: const EdgeInsets.only(top: PaddingSize.small, right: PaddingSize.small, left: PaddingSize.small),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 1,
            crossAxisCount: 2,
            mainAxisSpacing: 7,
            crossAxisSpacing: 7
          ),
            itemCount: controller.notes.length,
            itemBuilder: (context, index) {
              return NoteCart(note: controller.notes[index], index: index);
          },
        ),
      ),
    );
  }

  Widget emptyNotes() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image(
            height: 200, width: 200,
            image: AssetImage(Images.empty),
          ),
          Text(
            "Create your first note!",
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
