// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:notes_app/model/note_model.dart';
import 'package:notes_app/screens/dashboard_screen.dart';
import 'package:notes_app/screens/note_screens/add_new_note_page.dart';
import 'package:notes_app/screens/note_screens/edit_note_page.dart';
import 'package:notes_app/screens/home_page.dart';
import 'package:notes_app/screens/note_screens/note_detail_page.dart';

class AppRoute {
  static const String SPLASH = '/';
  static const String DASHBOARD = '/dashboard';
  static const String HOME = '/home';

  static const String ADD_NEW_NOTE = '/add_new_note';
  static const String EDIT_NOTE = '/edit_note';
  static const String NOTE_DETAILS = '/note_details';

  static String getNoteDetailsPage(Note note) {
    List<int> encoded = utf8.encode(jsonEncode(note.toJson()));
    String data = base64Encode(encoded);
    return '$NOTE_DETAILS?note=$data';
  }

  static String getEditNotePage(Note note) {
    List<int> encoded = utf8.encode(jsonEncode(note.toJson()));
    String data = base64Encode(encoded);
    return '$EDIT_NOTE?note=$data';
  }

  static var getRoutes = [
    //GetPage(name: AppRoute.SPLASH, page: () => Login()),
    GetPage(name: AppRoute.DASHBOARD, page: () => DashboardScreen()),
    GetPage(name: AppRoute.HOME, page: () => HomePage()),
    GetPage(name: AppRoute.ADD_NEW_NOTE, page: () => AddNewNotePage()),
    GetPage(name: AppRoute.EDIT_NOTE, page: () {
      List<int> decode = base64Decode(Get.parameters['note']!.replaceAll(' ', '+'));
      Note data = Note.fromJson(jsonDecode(utf8.decode(decode)));
      return EditNotePage(note: data);
    }),
    GetPage(name: AppRoute.NOTE_DETAILS, page: () {
      List<int> decode = base64Decode(Get.parameters['note']!.replaceAll(' ', '+'));
      Note data = Note.fromJson(jsonDecode(utf8.decode(decode)));
      return NoteDetailPage(note: data);
    }),
  ];
}
