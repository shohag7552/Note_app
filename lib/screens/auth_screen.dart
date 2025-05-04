import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:my_note_app/controller/auth_controller.dart';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

class AddUser extends StatefulWidget {
  const AddUser({super.key});

  @override
  State<AddUser> createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {


final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: <String>[
    DriveApi.driveFileScope,       // Manage files created by this app
    DriveApi.driveReadonlyScope,  // View metadata only
  ],
  clientId: '248792456508-dpg9n6eijfji2oeaj9obr6784daj2g62.apps.googleusercontent.com', // From Cloud Console
);

Future<DriveApi?> getDriveService() async {
  try {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    
    final googleAuth = await googleUser.authentication;
    final authHeaders = await googleUser.authHeaders;
    
    final authClient = auth.authenticatedClient(
      http.Client(),
      auth.AccessCredentials(
        auth.AccessToken('Bearer', googleAuth.accessToken!, DateTime.now().add(Duration(hours: 1))),
        googleAuth.idToken!,
        _googleSignIn.scopes,
      ),
    );
    
    return DriveApi(authClient);
  } catch (e) {
    print('Error getting Drive service: $e');
    return null;
  }
}

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
                TextButton(
                  onPressed: () {
                    // Get.find<FirebaseController>().uploadAllNotes();
                  },
                  child: const Text(
                    "Google Sign in",
                  ),
                ),
                
                TextButton(
                  onPressed: (){
                    getDriveService();
                  },
                  child: const Text(
                    "get User",
                  ),
                ),
                
              //  authController.getUserToken() == null ? TextButton(
              //     onPressed: () async {
              //       authController.googleLogin(googleSignIn);
              //     },
              //     child: const Text(
              //       "google sign in",
              //       style: TextStyle(color: Colors.green),
              //     ),
              //   ) : const SizedBox(),
                
              //   authController.getUserToken() != null ? TextButton(
              //     onPressed: () async {
              //       authController.googleLogOut(googleSignIn);
              //     },
              //     child: const Text(
              //       "google sign out",
              //       style: TextStyle(color: Colors.red),
              //     ),
              //   ) : const SizedBox(),
              ],
            );
          }
        ),
      ),
    );
  }
}