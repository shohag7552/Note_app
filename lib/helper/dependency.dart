import 'package:get/get.dart';
import 'package:my_note_app/appwrite/repository/app_write_repository.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/background_controller.dart';

Future<void> init() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  Get.lazyPut(() => prefs);
  Get.lazyPut(() => NoteController(sharedPreferences: Get.find()));
  // Get.lazyPut(() => FirebaseController());
  Get.lazyPut(() => AuthController(sharedPreferences: Get.find()));
  Get.lazyPut(() => BackgroundController(sharedPreferences: Get.find()));
  Get.lazyPut(() => AppWriteRepository());
}