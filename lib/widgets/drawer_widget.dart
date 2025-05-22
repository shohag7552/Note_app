import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';

import '../screens/auth_screen.dart';
class DrawerWidget extends StatelessWidget {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    print('39487598347589>>>>>>> ${Get.find<NoteController>().appLockStatus} // ${Get.find<NoteController>().isPasswordActive()}');
    return Drawer(
      child: ListView(
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
            onTap: () {
              Get.to(const AddUser());
            },
          ),
          GetBuilder<NoteController>(
            builder: (noteController) {
              return ListTile(
                leading: Icon(Icons.settings),
                title: const Text('App Lock'),
                onTap: () {
                  noteController.activePassword(true);
                  // Navigator.pop(context);
                },
                trailing: CupertinoSwitch(
                  value: noteController.appLockStatus,
                  onChanged: (status){
                    print('===== check > $status');
                    noteController.activePassword(status);

                  },
                ),
              );
            }
          ),
        ],
      ),
    );
  }
}
