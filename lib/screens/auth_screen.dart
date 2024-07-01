// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:notes_app/controller/auth_controller.dart';
// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});
//
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }
//
// class _AuthScreenState extends State<AuthScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Auth')),
//       body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
//
//         Center(
//           child: TextButton(
//             onPressed: (){
//               // Get.find<AuthController>().upload();
//             },
//             child: const Text('Google Sign in'),
//           ),
//         ),
//       ]),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';

// Import the firebase_core and cloud_firestore plugin
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notes_app/controller/auth_controller.dart';
import 'package:notes_app/controller/firebase_controller.dart';
import 'package:uuid/uuid.dart';

class AddUser extends StatelessWidget {
  const AddUser({super.key});

  @override
  Widget build(BuildContext context) {
    GoogleSignIn googleSignIn = GoogleSignIn();

    return Scaffold(
      body: Center(
        child: GetBuilder<AuthController>(
          builder: (authController) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    Get.find<FirebaseController>().uploadAllNotes();
                  },
                  child: const Text(
                    "Add User",
                  ),
                ),

                TextButton(
                  onPressed: (){
                    Get.find<FirebaseController>().getNotesFromCloud();
                  },
                  child: const Text(
                    "get User",
                  ),
                ),

               authController.getUserToken() == null ? TextButton(
                  onPressed: () async {
                    authController.googleLogin(googleSignIn);
                  },
                  child: const Text(
                    "google sign in",
                    style: TextStyle(color: Colors.green),
                  ),
                ) : const SizedBox(),

                authController.getUserToken() != null ? TextButton(
                  onPressed: () async {
                    authController.googleLogOut(googleSignIn);
                  },
                  child: const Text(
                    "google sign out",
                    style: TextStyle(color: Colors.red),
                  ),
                ) : const SizedBox(),
              ],
            );
          }
        ),
      ),
    );
  }
}