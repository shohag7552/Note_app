import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/drive/drive_repository.dart';
import 'package:my_note_app/helper/note_image_helper.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> init() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Core dependencies.
  Get.lazyPut(() => prefs);
  await NoteImageHelper.init();

  // Services — must be registered before controllers that depend on them.
  Get.lazyPut(
    () => DriveRepository(
      clientProvider: ({bool forceRefresh = false}) =>
          Get.find<AuthController>().driveClient(forceRefresh: forceRefresh),
    ),
    fenix: true,
  );
  Get.lazyPut(() => SyncService(), fenix: true);

  // Controllers.
  Get.lazyPut(() => NoteController(sharedPreferences: Get.find()), fenix: true);
  Get.lazyPut(() => AuthController(sharedPreferences: Get.find()), fenix: true);
  Get.lazyPut(() => BackgroundController(sharedPreferences: Get.find()), fenix: true);
}