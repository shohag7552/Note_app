import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:notes_app/controller/auth_controller.dart';
import 'package:notes_app/controller/firebase_controller.dart';
import 'package:notes_app/controller/note_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> init() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  Get.lazyPut(() => prefs);
  Get.lazyPut(() => NoteController());
  Get.lazyPut(() => FirebaseController());
  Get.lazyPut(() => AuthController(
    sharedPreferences: Get.find()
  ));
}