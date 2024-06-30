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
import 'package:notes_app/controller/firebase_controller.dart';
import 'package:uuid/uuid.dart';

class AddUser extends StatelessWidget {
  const AddUser({super.key});

  @override
  Widget build(BuildContext context) {
    const List<String> scopes = <String>[
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ];

    GoogleSignIn _googleSignIn = GoogleSignIn(
      // Optional clientId
      // clientId: 'your-client_id.apps.googleusercontent.com',
      scopes: scopes,
    );

    return Scaffold(
      body: Center(
        child: Column(
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
              // onPressed: getUser,
              onPressed: (){
                Get.find<FirebaseController>().getNotesFromCloud();
              },
              child: const Text(
                "get User",
              ),
            ),

            TextButton(
              // onPressed: getUser,
              onPressed: () async {
                try {
                  await _googleSignIn.signIn();
                } catch (error) {
                  print(error);
                }
                // isAuthorized = await _googleSignIn.canAccessScopes(scopes);
                GoogleSignInAccount googleAccount = (await _googleSignIn.signIn())!;
                GoogleSignInAuthentication auth = await googleAccount.authentication;

                print('====google data : ${googleAccount.email} // ${googleAccount.id} // ${googleAccount.displayName}');
              },
              child: const Text(
                "google sign in",
              ),
            ),
          ],
        ),
      ),
    );
  }
}