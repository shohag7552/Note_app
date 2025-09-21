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

  BackgroundController({required this.sharedPreferences}) {
    _getBackgroundImage();
  }

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

  XFile? _image;
  XFile? get backgroundImage => _image;
  //
  // double _colorOpacity = 0.1;
  // double get colorOpacity => _colorOpacity = 0.1;

  Future<XFile?> pickBackgroundImage({bool isRemove = false}) async {
    if(isRemove) {
      _image = null;
    } else {
      final ImagePicker picker = ImagePicker();
      _image = await picker.pickImage(source: ImageSource.gallery);

      if(_image != null) {
        // Save the image path to shared preferences
        await sharedPreferences.setString(AppConstants.backgroundImageKey, _image!.path);
      }
      // Get.dialog(BackgroundColorOpacityDialog(), barrierColor: Colors.transparent).then((v) {
      //   print('====tttt===> $v');
      //   _colorOpacity = v;
      // });
      // showDialog(
      //     context: Get.context!,
      //     builder: (BuildContext context) {
      //       return BackgroundColorOpacityDialog();
      //     });
    }

    update();
    return _image;
  }


  void setOpacity(double value) {
    sharedPreferences.setDouble(AppConstants.opacityKey, value);
  }

  double getOpacity() {
    return sharedPreferences.getDouble(AppConstants.opacityKey) ?? 0.1;
  }

  void _getBackgroundImage() {
    String? savedImagePath = sharedPreferences.getString(AppConstants.backgroundImageKey);
    if (savedImagePath != null && savedImagePath.isNotEmpty) {
      _image = XFile(savedImagePath);
    } else {
      _image = null;
    }
    update();
  }


}