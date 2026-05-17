import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_note_app/appwrite/repository/app_write_repository.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;

  BackgroundController({required this.sharedPreferences});

  AppWriteRepository _appWriteRepository = AppWriteRepository();



  Future<void> uploadAllNotes() async {

    if(Get.find<NoteController>().notes.isEmpty) {
      await Get.find<NoteController>().getAllNotes();
    }

    for(Note note in Get.find<NoteController>().notes) {
      await _addNote(note);
    }
  }

  Future<bool> _addNote(Note note) async {

    try {
      String? userEmail = Get.find<AuthController>().getUserToken();
      if(userEmail == null) {
        print('you are not authenticated');
        return false;
      }
      note.authorEmail = userEmail;
      await _appWriteRepository.createNote(note: note);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> getAllNotes() async {
    String? userEmail = Get.find<AuthController>().getUserToken();
    if(userEmail == null) {
      print('you are not authenticated');
      return;
    }
    List<Note> notes = await _appWriteRepository.getNotes(authorEmail: userEmail, limit: 100, offset: 1);
    print('===notes===> ${notes.map((e) => e.toJson())}');
    update();
  }

}