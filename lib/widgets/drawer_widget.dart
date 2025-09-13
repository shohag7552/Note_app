import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/config/app_write_service.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/model/note_model.dart';

import '../screens/auth_screen.dart';
class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  final AppWriteService appwriteService = AppWriteService();
  @override
  void initState() {
    super.initState();

    Get.find<NoteController>().appLockStatus = Get.find<NoteController>().isPasswordActive();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).cardColor,
      child: Container(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
        child: GetBuilder<NoteController>(
            builder: (noteController) {
            return ListView(
              // Important: Remove any padding from the ListView.
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Text('Drawer Header'),
                ),
                ListTile(
                  title: const Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Authentication'),
                  onTap: () async {
                    // Get.to(const AddUser());
                    print('=======here=======');
                    // await appwriteService.addNote(
                    //   // Note(id: 1, title: 'This is title', content: 'This is description.', dateTimeEdited: DateTime.now().toString(), dateTimeCreated: DateTime.now().toString()),
                    //   Note(id: 2, title: 'This is title 2', content: 'This is description 2.', dateTimeEdited: DateTime.now().toString(), dateTimeCreated: DateTime.now().toString()),
                    // );
                    // await appwriteService.updateNote(
                    //   Note(id: 2, title: 'This is title 3----------', content: 'This is description 2.', dateTimeEdited: DateTime.now().toString(), dateTimeCreated: DateTime.now().toString()),
                    // );
                    await appwriteService.getNoteList();

                    // await appwriteService.deleteNote('68c5306acad23e03a01c');

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Note added!")),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: const Text('App Lock'),
                  onTap: () {},
                  trailing: CupertinoSwitch(
                    value: noteController.appLockStatus,
                    activeTrackColor: Theme.of(context).primaryColor,
                    onChanged: (status){
                      noteController.activePassword(status);

                    },
                  ),
                ),

                ListTile(
                  leading: Icon(Icons.nights_stay),
                  title: const Text('Dark Mode'),
                  onTap: () {},
                  trailing: CupertinoSwitch(
                    value: noteController.darkTheme,
                    activeTrackColor: Theme.of(context).primaryColor,
                    onChanged: (status){
                      noteController.toggleTheme();
                    },
                  ),
                ),

              ],
            );
          }
        ),
      ),
    );
  }
}
