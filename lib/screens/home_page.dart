import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes_app/routing/app_routes.dart';
import 'package:notes_app/screens/search_screen.dart';
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
  // final controller = Get.put(NoteController());

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
          // floatingActionButton: FloatingActionButton.extended(
          //   onPressed: () => Get.toNamed(AppRoute.ADD_NEW_NOTE),
          //   label: Text(
          //     "Add new note", textAlign: TextAlign.center,
          //     style: fontStyleMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color, fontSize: FontSize.medium),
          //   ),
          //   icon: const Icon(Icons.add),
          // ),
          floatingActionButton: Material(
            child: FloatingActionButton(
              elevation: 6,
              onPressed: () => Get.toNamed(AppRoute.ADD_NEW_NOTE),
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(500)),
              child: Icon(Icons.add, color: Theme.of(context).cardColor),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: Container(
            height: 80,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 10)],
            ),
            // child: Center(
            //   child: FloatingActionButton(
            //     isExtended: true,
            //     onPressed: (){},
            //   ),
            // ),
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
        /*child: ListView.builder(
          shrinkWrap: false,
          itemCount: controller.notes.length,
          itemBuilder: (context, index) {
            return NoteCart();
            return GestureDetector(
              onTap: () => Get.toNamed(AppRoute.NOTE_DETAILS, arguments: index),
              onLongPress: () {
                showDialog(context: context, builder: (context) {
                    return AlertDialogWidget(
                      headingText: "Are you sure you want to delete this note?",
                      contentText: "This will delete the note permanently. You cannot undo this action.",
                      confirmFunction: () {
                        controller.deleteNote(controller.notes[index].id!);
                        Get.back();
                      },
                      declineFunction: () {
                        Get.back();
                      },
                    );
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: controller.notes[index].color!.toColor(),
                    borderRadius: BorderRadius.circular(RadiusSize.medium),
                  ),
                  padding: const EdgeInsets.all(PaddingSize.medium),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.notes[index].title!,
                            style: fontStyleBold.copyWith(fontSize: FontSize.mediumLarge),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: PaddingSize.small),

                          Text(
                            controller.notes[index].content!,
                            style: fontStyleMedium.copyWith(fontSize: FontSize.extraMedium),
                            overflow: TextOverflow.ellipsis, maxLines: 2,
                          ),
                          const SizedBox(height: PaddingSize.small),

                          Text(
                            controller.notes[index].dateTimeEdited!,
                            style: fontStyleNormal.copyWith(fontSize: FontSize.small),
                          ),

                          Text(
                            controller.notes[index].color??'',
                            style: fontStyleNormal.copyWith(fontSize: FontSize.small),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: PaddingSize.large),

                    InkWell(
                      onTap: () => controller.favoriteNote(controller.notes[index].id!),
                      child: Icon(
                        controller.notes[index].isFavorite == true ? Icons.favorite : Icons.favorite_border,
                      ),
                    ),

                  ]),
                ),
              ),
            );
          },
        ),*/
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
