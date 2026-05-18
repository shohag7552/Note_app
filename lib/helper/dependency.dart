import 'package:get/get.dart';
import 'package:my_note_app/appwrite/repository/app_write_repository.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> init() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Core dependencies.
  Get.lazyPut(() => prefs);

  // Services — must be registered before controllers that depend on them.
  Get.lazyPut(() => AppWriteRepository(), fenix: true);
  Get.lazyPut(() => SyncService(), fenix: true);

  // Controllers.
  Get.lazyPut(() => NoteController(sharedPreferences: Get.find()), fenix: true);
  Get.lazyPut(() => AuthController(sharedPreferences: Get.find()), fenix: true);
  Get.lazyPut(() => BackgroundController(sharedPreferences: Get.find()), fenix: true);
}