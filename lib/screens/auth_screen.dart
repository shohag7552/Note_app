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
import 'package:notes_app/controller/firebase_controller.dart';
import 'package:uuid/uuid.dart';

class AddUser extends StatelessWidget {
  const AddUser({super.key});

  @override
  Widget build(BuildContext context) {
    String userId = 'this_is_user_id';
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // // Create a CollectionReference called users that references the firestore collection
    // CollectionReference users = FirebaseFirestore.instance.collection('users');
    //
    // Future<bool> addUser() async {
    //   // Call the user's CollectionReference to add a new user
    //   //  users
    //   //     .add({
    //   //   'full_name': 'fullName', // John Doe
    //   //   'company': 'company', // Stokes and Sons
    //   //   'age': 'age' // 42
    //   // })
    //   //     .then((value) => print("User Added"))
    //   //     .catchError((error) => print("Failed to add user: $error"));
    //
    //   try {
    //     var uuid = const Uuid().v4();
    //     print('===ss====> $uuid');
    //     DateTime data = new DateTime.now();
    //     await _firestore
    //         .collection('users')
    //         .doc(userId)
    //         .collection('notes')
    //         .doc(uuid)
    //         .set({
    //       'id': uuid,
    //       'subtitle': 'subtitle',
    //       'isDon': false,
    //       'time': data,
    //       'title': 'title',
    //     });
    //     return true;
    //   } catch (e) {
    //     print(e);
    //     return true;
    //   }
    // }
    //
    Future<bool> getUser() async {
      // Call the user's CollectionReference to add a new user
      //  users
      //     .add({
      //   'full_name': 'fullName', // John Doe
      //   'company': 'company', // Stokes and Sons
      //   'age': 'age' // 42
      // })
      //     .then((value) => print("User Added"))
      //     .catchError((error) => print("Failed to add user: $error"));

      try {
        // var uuid = const Uuid().v4();
        // print('===ss====> $uuid');
        // DateTime data = new DateTime.now();
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notes')
            .get()
            .then((QuerySnapshot<Map<String, dynamic>> value){
              print('========ff====> ${value.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                print('=========ssss====> $data');
              })}');
        });
        return true;
      } catch (e) {
        print(e);
        return true;
      }
    }

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                Get.find<FirebaseController>().uploadAllNotes();
              },
              child: Text(
                "Add User",
              ),
            ),

            TextButton(
              // onPressed: getUser,
              onPressed: (){
                Get.find<FirebaseController>().getNotesFromCloud();
              },
              child: Text(
                "get User",
              ),
            ),
          ],
        ),
      ),
    );
  }
}