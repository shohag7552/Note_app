import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database_helper/database_helper.dart';
import '../routing/app_routes.dart';

class NoteController extends GetxController implements GetxService{
  final SharedPreferences sharedPreferences;
  NoteController({required this.sharedPreferences}) {
    _loadCurrentTheme();
  }

  final titleController = TextEditingController();
  final contentController = TextEditingController();

  var notes = <Note>[];

  bool appLockStatus = false;

  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;

  String _currentFont = 'Inter';
  String get currentFont => _currentFont;

  bool showFavouritesOnly = false;

  void toggleFavouritesFilter() {
    showFavouritesOnly = !showFavouritesOnly;
    update();
  }

  @override
  void onInit() {
    getAllNotes();
    super.onInit();
  }

  bool isEmpty() {
    return notes.isEmpty;
  }

  Future<void> addNoteToDatabase({required String title, required String content, String? color, Note? cloudNote}) async {
    Note note;
    if(cloudNote != null) {
      note = Note(
        // id: int.parse(cloudNote.id.toString()),
        title: cloudNote.title,
        content: cloudNote.content.toString(),
        dateTimeEdited: cloudNote.dateTimeEdited,
        dateTimeCreated: cloudNote.dateTimeCreated,
        isFavorite: cloudNote.isFavorite,
        color: cloudNote.color,
      );
    } else {
      note = Note(
        title: title,
        content: content,
        dateTimeEdited: DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now()),
        dateTimeCreated: DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now()),
        isFavorite: 0,
        color: color,
      );
    }

    print('=====> ${note.toJson()}');
    await DatabaseHelper.instance.addNote(note);
    titleController.text = "";
    contentController.text = "";
    if(cloudNote == null) {
      getAllNotes();
      Get.offAllNamed(AppRoute.HOME);
    }
  }

  void updateNote(Note note) async {
    await DatabaseHelper.instance.updateNote(note);
    titleController.text = "";
    contentController.text = "";
    getAllNotes();
    Get.offAllNamed(AppRoute.HOME);
  }

  void deleteNote(int id) async {
    Note note = Note(
      id: id,
    );
    await DatabaseHelper.instance.deleteNote(note);
    getAllNotes();
  }

  Future<void> updateNoteColor(int id, String color) async {
    final note = notes.firstWhere((n) => n.id == id);
    note.color = color;
    await DatabaseHelper.instance.updateNote(note);
    getAllNotes();
  }

  void favoriteNote(int id) async {
    Note note = notes.firstWhere((note) => note.id == id);
    if (note.isFavorite == 1) {
      note.isFavorite = 0; // Mark as not favorite
    } else {
      note.isFavorite = 1; // Mark as favorite
    }
    await DatabaseHelper.instance.updateNote(note);
    getAllNotes();
  }

  Future<void> deleteAllNotes() async {
    await DatabaseHelper.instance.deleteAllNotes();
    getAllNotes();
  }

  Future<void> getAllNotes() async {
    notes = await DatabaseHelper.instance.getNoteList();
    for (var note in notes) {
      print('===${notes.indexOf(note)}==> ${note.toJson()}');
    }
    update();
  }

  void shareNote(String content) {
    // Share.share(content);
    SharePlus.instance.share(
        ShareParams(text: content)
    );
  }

  bool isContainPassword() {
    return sharedPreferences.containsKey(AppConstants.passKey);
  }

  Future<bool> setPassword(String pass) async {
    return await sharedPreferences.setString(AppConstants.passKey, pass);
  }

  String? getPassword() {
    return sharedPreferences.getString(AppConstants.passKey);
  }

  Future<bool> setSuggestions(List<String> answers) async {
    return await sharedPreferences.setStringList(AppConstants.suggestionsKey, answers);
  }

  Future<List<String>?> getSuggestions() async {
    return sharedPreferences.getStringList(AppConstants.suggestionsKey);
  }

  bool isPasswordActive() {
    return sharedPreferences.getBool(AppConstants.passActiveKey)?? false;
    // return sharedPreferences.containsKey(AppConstants.passActiveKey);
  }

  Future<bool> activePassword(bool status) async {
    appLockStatus = status;
    update();
    print('=s0=-> $appLockStatus // ${await sharedPreferences.setBool(AppConstants.passActiveKey, status)}');
    return await sharedPreferences.setBool(AppConstants.passActiveKey, status);
  }

  void toggleTheme() {
    _darkTheme = !_darkTheme;
    sharedPreferences.setBool(AppConstants.theme, _darkTheme);
    update();
  }

  void changeFont(String fontFamily) {
    _currentFont = fontFamily;
    sharedPreferences.setString(AppConstants.fontKey, fontFamily);
    update();
  }

  void _loadCurrentTheme() async {
    _darkTheme = sharedPreferences.getBool(AppConstants.theme) ?? false;
    _currentFont = sharedPreferences.getString(AppConstants.fontKey) ?? 'Inter';
    update();
  }

}
