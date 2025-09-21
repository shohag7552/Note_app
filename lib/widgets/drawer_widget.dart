import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/appwrite/repository/app_write_repository.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/model/note_model.dart';

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
            return GetBuilder<AuthController>(
              builder: (authController) {
                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                      child: authController.getUserToken() != null ? Column(children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              authController.getUser()?.imageUrl ?? 'https://www.gravatar.com/avatar/placeholder',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          authController.getUser()?.name ?? 'Guest User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),

                        Text(
                          authController.getUser()?.email ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ]) : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 10,
                          children: [
                            const Text(
                              'Welcome, Guest',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),

                            ElevatedButton(
                              onPressed: () {
                                Get.find<AuthController>().googleLogin();
                              },
                              child: const Text('Login'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    ListTile(
                      title: const Text('Home'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),

                    ListTile(
                      title: const Text('get user'),
                      onTap: () async {

                        Get.find<BackgroundController>().getAllNotes();

                      },
                    ),

                    ListTile(
                      title: const Text('upload notes'),
                      onTap: () async {

                        Get.find<BackgroundController>().uploadAllNotes().then((v) {

                        });

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


                    if(authController.getUserToken() != null)
                      ListTile(
                        leading: Icon(Icons.logout_outlined),
                        title: const Text('Logout'),
                        onTap: () async {
                          Get.find<AuthController>().googleLogOut();
                        },
                      ),

                  ],
                );
              }
            );
          }
        ),
      ),
    );
  }
}
