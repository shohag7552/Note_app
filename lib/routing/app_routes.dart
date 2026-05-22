// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:get/get.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/screens/auth/welcome_screen.dart';
import 'package:my_note_app/screens/auth/sync_progress_screen.dart';
import 'package:my_note_app/screens/home_page.dart';
import 'package:my_note_app/screens/note_screens/add_new_note_page.dart';
import 'package:my_note_app/screens/note_screens/edit_note_page.dart';
import 'package:my_note_app/screens/note_screens/note_detail_page.dart';
import 'package:my_note_app/screens/pass_screen/app_lock_screen.dart';
import 'package:my_note_app/screens/pass_screen/forget_pass_screen.dart';
import 'package:my_note_app/screens/pass_screen/pass_screen.dart';
import 'package:my_note_app/screens/appearance_screen.dart';
import 'package:my_note_app/screens/profile_screen.dart';

class AppRoute {
  static const String SPLASH = '/';
  static const String WELCOME = '/welcome';
  static const String SYNC_PROGRESS = '/sync_progress';
  static const String pass = '/password';
  static const String forgetPass = '/forget_password';
  static const String appLock = '/app_lock';
  static const String HOME = '/home';

  static const String ADD_NEW_NOTE = '/add_new_note';
  static const String EDIT_NOTE = '/edit_note';
  static const String NOTE_DETAILS = '/note_details';
  static const String APPEARANCE = '/appearance';
  static const String PROFILE = '/profile';

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
    GetPage(name: AppRoute.WELCOME, page: () => const WelcomeScreen()),
    GetPage(name: AppRoute.SYNC_PROGRESS, page: () => const SyncProgressScreen()),
    GetPage(name: AppRoute.pass, page: () => const PassScreen()),
    GetPage(name: AppRoute.forgetPass, page: () => const ForgetPassScreen()),
    GetPage(name: AppRoute.appLock, page: () => const AppLockScreen()),
    GetPage(name: AppRoute.HOME, page: () => const HomePage()),
    GetPage(name: AppRoute.APPEARANCE, page: () => const AppearanceScreen()),
    GetPage(name: AppRoute.ADD_NEW_NOTE, page: () => const AddNewNotePage()),
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
    GetPage(name: AppRoute.PROFILE, page: () => const ProfileScreen()),
  ];
}
