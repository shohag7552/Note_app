import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/screens/auth_screen.dart';
import 'package:my_note_app/screens/note_screens/search_screen.dart';
import 'package:my_note_app/utils/font_size.dart';
import 'package:my_note_app/utils/images.dart';
import 'package:my_note_app/utils/padding_size.dart';
import 'package:my_note_app/utils/style.dart';
import 'package:my_note_app/widgets/drawer_widget.dart';
import 'package:my_note_app/widgets/note_card.dart';
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
            leading: Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
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
          drawer: DrawerWidget(),
          body: GetBuilder<NoteController>(
            builder: (_) => controller.isEmpty() ? emptyNotes() : viewNotes(controller),
          ),
          floatingActionButton: Material(
            child: FloatingActionButton(
              elevation: 6,
              onPressed: () => Get.toNamed(AppRoute.ADD_NEW_NOTE),
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
              child: Icon(Icons.add, color: Theme.of(context).cardColor),
            ),
          ),
        );
      }
    );
  }

  Widget viewNotes(NoteController controller) {
    return Scrollbar(
      child: Container(
        padding: const EdgeInsets.only(top: PaddingSize.small, right: PaddingSize.small, left: PaddingSize.small),
        // child: ListView.builder(
        //   itemCount: controller.notes.length,
        //   shrinkWrap: true,
        //   itemBuilder: (context, index) {
        //     // return Container(
        //     //   margin: const EdgeInsets.only(bottom: PaddingSize.small),
        //     //   height: 150, width: double.infinity,
        //     //   decoration: BoxDecoration(
        //     //     color: Theme.of(context).cardColor,
        //     //     borderRadius: BorderRadius.circular(10),
        //     //     boxShadow: [
        //     //       BoxShadow(
        //     //         color: Colors.grey.withOpacity(0.2),
        //     //         spreadRadius: 1,
        //     //         blurRadius: 5,
        //     //         offset: const Offset(0, 3),
        //     //       ),
        //     //     ],
        //     //   ),
        //     // );
        //     return Padding(
        //       padding: const EdgeInsets.only(bottom: 10),
        //       child: NoteCart(note: controller.notes[index], index: index),
        //     );
        //   },
        // ),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            childAspectRatio: 0.7,
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
