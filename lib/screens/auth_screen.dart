import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';

class AddUser extends StatelessWidget {
  const AddUser({super.key});

  @override
  Widget build(BuildContext context) {
    // GoogleSignIn googleSignIn = GoogleSignIn();

    return Scaffold(
      body: Center(
        child: GetBuilder<AuthController>(
          builder: (authController) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
               //  TextButton(
               //    onPressed: () {
               //      Get.find<FirebaseController>().uploadAllNotes();
               //    },
               //    child: const Text(
               //      "Add User",
               //    ),
               //  ),
               //
               //  TextButton(
               //    onPressed: (){
               //      Get.find<FirebaseController>().getNotesFromCloud();
               //    },
               //    child: const Text(
               //      "get User",
               //    ),
               //  ),
               //
               // authController.getUserToken() == null ? TextButton(
               //    onPressed: () async {
               //      authController.googleLogin(googleSignIn);
               //    },
               //    child: const Text(
               //      "google sign in",
               //      style: TextStyle(color: Colors.green),
               //    ),
               //  ) : const SizedBox(),
               //
               //  authController.getUserToken() != null ? TextButton(
               //    onPressed: () async {
               //      authController.googleLogOut(googleSignIn);
               //    },
               //    child: const Text(
               //      "google sign out",
               //      style: TextStyle(color: Colors.red),
               //    ),
               //  ) : const SizedBox(),
              ],
            );
          }
        ),
      ),
    );
  }
}