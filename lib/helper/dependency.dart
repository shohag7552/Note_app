import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:notes_app/controller/auth_controller.dart';
import 'package:notes_app/controller/firebase_controller.dart';
import 'package:notes_app/controller/note_controller.dart';

Future<void> init() async {
  Get.lazyPut(() => NoteController());
  Get.lazyPut(() => FirebaseController());
  // Get.lazyPut(() => AuthController(googleSignIn: GoogleSignIn(
  //   scopes: [
  //   'email',
  //   'https://www.googleapis.com/auth/drive',
  //   ],
  // )));
}