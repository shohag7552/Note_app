import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database_helper/database_helper.dart';
import '../routing/app_routes.dart';

class NoteController extends GetxController implements GetxService {
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

  // ── PIN hashing ──────────────────────────────────────────────────────────
  static String _hashPin(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void onInit() {
    _migratePasswordIfNeeded();
    getAllNotes();
    super.onInit();
  }

  // ── Notes ────────────────────────────────────────────────────────────────
  bool isEmpty() => notes.isEmpty;

  void toggleFavouritesFilter() {
    showFavouritesOnly = !showFavouritesOnly;
    update();
  }

  Future<void> addNoteToDatabase({
    required String title,
    required String content,
    String? color,
    Note? cloudNote,
  }) async {
    Note note;
    if (cloudNote != null) {
      note = Note(
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
    await DatabaseHelper.instance.addNote(note);
    titleController.text = '';
    contentController.text = '';
    if (cloudNote == null) {
      getAllNotes();
      Get.offAllNamed(AppRoute.HOME);
    }
  }

  void updateNote(Note note) async {
    await DatabaseHelper.instance.updateNote(note);
    titleController.text = '';
    contentController.text = '';
    getAllNotes();
    Get.offAllNamed(AppRoute.HOME);
  }

  void deleteNote(int id) async {
    await DatabaseHelper.instance.deleteNote(Note(id: id));
    getAllNotes();
  }

  Future<void> updateNoteColor(int id, String color) async {
    final note = notes.firstWhere((n) => n.id == id);
    note.color = color;
    await DatabaseHelper.instance.updateNote(note);
    getAllNotes();
  }

  void favoriteNote(int id) async {
    final note = notes.firstWhere((n) => n.id == id);
    note.isFavorite = note.isFavorite == 1 ? 0 : 1;
    await DatabaseHelper.instance.updateNote(note);
    getAllNotes();
  }

  Future<void> deleteAllNotes() async {
    await DatabaseHelper.instance.deleteAllNotes();
    getAllNotes();
  }

  Future<void> getAllNotes() async {
    notes = await DatabaseHelper.instance.getNoteList();
    update();
  }

  void shareNote(String content) {
    SharePlus.instance.share(ShareParams(text: content));
  }

  // ── Password / Lock ──────────────────────────────────────────────────────
  bool isContainPassword() =>
      sharedPreferences.containsKey(AppConstants.passKey);

  /// Stores a SHA-256 hash of [pass].
  Future<bool> setPassword(String pass) async {
    return sharedPreferences.setString(AppConstants.passKey, _hashPin(pass));
  }

  /// Returns true when [pin] matches the stored hash.
  bool verifyPassword(String pin) {
    final stored = sharedPreferences.getString(AppConstants.passKey);
    if (stored == null || stored.isEmpty) return false;
    return _hashPin(pin) == stored;
  }

  /// Migrates a plain-text PIN (length ≠ 64) to a SHA-256 hash transparently.
  void _migratePasswordIfNeeded() {
    final stored = sharedPreferences.getString(AppConstants.passKey);
    if (stored != null && stored.length != 64) {
      sharedPreferences.setString(AppConstants.passKey, _hashPin(stored));
    }
  }

  Future<bool> setSuggestions(List<String> answers) async =>
      sharedPreferences.setStringList(AppConstants.suggestionsKey, answers);

  Future<List<String>?> getSuggestions() async =>
      sharedPreferences.getStringList(AppConstants.suggestionsKey);

  bool isPasswordActive() =>
      sharedPreferences.getBool(AppConstants.passActiveKey) ?? false;

  Future<bool> activePassword(bool status) async {
    appLockStatus = status;
    update();
    return sharedPreferences.setBool(AppConstants.passActiveKey, status);
  }

  // ── Theme / Font ─────────────────────────────────────────────────────────
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

  void _loadCurrentTheme() {
    _darkTheme = sharedPreferences.getBool(AppConstants.theme) ?? false;
    _currentFont = sharedPreferences.getString(AppConstants.fontKey) ?? 'Inter';
    update();
  }
}
