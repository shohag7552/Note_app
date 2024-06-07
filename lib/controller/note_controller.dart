import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/model/note_model.dart';
import 'package:share/share.dart';

import '../database_helper/database_helper.dart';
import '../routing/app_routes.dart';

class NoteController extends GetxController implements GetxService{
  final titleController = TextEditingController();
  final contentController = TextEditingController();

  var notes = <Note>[];

  @override
  void onInit() {
    getAllNotes();
    super.onInit();
  }

  bool isEmpty() {
    return notes.isEmpty;
  }

  void addNoteToDatabase({required String title, required String content, String? color}) async {
    // String title = titleController.text;
    // String content = contentController.text;
    Note note = Note(
      title: title,
      content: content,
      dateTimeEdited: DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now()),
      dateTimeCreated: DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now()),
      isFavorite: 0,
      color: color,
    );
    print('=====> ${note.toJson()}');
    await DatabaseHelper.instance.addNote(note);
    titleController.text = "";
    contentController.text = "";
    getAllNotes();
    Get.back();
  }

  void updateNote(Note note) async {
    // final title = titleController.text;
    // final content = contentController.text;
    // Note note = Note(
    //   id: id,
    //   title: title,
    //   content: content,
    //   dateTimeEdited: DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now()),
    //   dateTimeCreated: dTCreated,
    //   isFavorite: isFavourite,
    // );
    print('=====ff====gg===> ${note.toJson()}');
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

  void deleteAllNotes() async {
    await DatabaseHelper.instance.deleteAllNotes();
    getAllNotes();
  }

  void getAllNotes() async {
    notes = await DatabaseHelper.instance.getNoteList();
    for (var note in notes) {
      print('===${notes.indexOf(note)}==> ${note.toJson()}');
    }
    update();
  }

  void shareNote(String content) {
    Share.share(content);
  }
}
