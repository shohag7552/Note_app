import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';

import '../screens/auth_screen.dart';
class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {

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
                  onTap: () {
                    Get.to(const AddUser());
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock),
                  title: const Text('App Lock'),
                  onTap: () {},
                  trailing: CupertinoSwitch(
                    value: noteController.appLockStatus,
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
