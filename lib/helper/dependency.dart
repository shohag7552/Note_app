import 'package:get/get.dart';
import 'package:notes_app/controller/note_controller.dart';

Future<void> init() async {
  Get.lazyPut(() => NoteController());
}