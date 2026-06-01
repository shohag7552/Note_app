import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database_helper/database_helper.dart';
import '../routing/app_routes.dart';

class NoteController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  NoteController({required this.sharedPreferences}) {
    _loadCurrentTheme();
    _loadSortPreferences();
  }

  final titleController = TextEditingController();
  final contentController = TextEditingController();

  var notes = <Note>[];
  var deletedNotes = <Note>[];
  bool appLockStatus = false;

  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;

  String _currentFont = 'Inter';
  String get currentFont => _currentFont;

  int _layoutIndex = 0; // 0: Masonry, 1: List, 2: Dense Grid, 3: Quilted
  int get layoutIndex => _layoutIndex;

  int _cardDesignIndex = 0; // 0: Classic, 1: Tinted, 2: Minimalist
  int get cardDesignIndex => _cardDesignIndex;

  bool showFavouritesOnly = false;

  String _sortBy = 'edited'; // 'edited' = updatedAt, 'created' = recently added
  String get sortBy => _sortBy;

  String _sortOrder = 'desc'; // 'desc' = newest first, 'asc' = oldest first
  String get sortOrder => _sortOrder;

  // ── Multi-select ─────────────────────────────────────────────────────────
  final selectedIds = <int>{};
  bool get isSelectionMode => selectedIds.isNotEmpty;

  void toggleSelection(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
    update();
  }

  void selectAll(List<Note> displayedNotes) {
    selectedIds.addAll(displayedNotes.map((n) => n.id!));
    update();
  }

  void clearSelection() {
    selectedIds.clear();
    update();
  }

  Future<void> deleteSelectedNotes() async {
    final idsToDelete = selectedIds.toList();
    selectedIds.clear();

    // Soft-delete all selected notes
    await DatabaseHelper.instance.softDeleteNotesByIds(idsToDelete);

    // Sync each to cloud
    final notesToSync = notes.where((n) => idsToDelete.contains(n.id)).toList();
    for (final note in notesToSync) {
      note.isDeleted = 1;
      note.deletedAt = DateTime.now().toUtc().toIso8601String();
      note.syncStatus = 'pending';
      _trySyncNote(note);
    }

    getAllNotes();
  }

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
    final now = DateFormat("dd-MM-yyyy hh:mm a").format(DateTime.now());

    final Note note = cloudNote != null
        ? Note(
            title: cloudNote.title,
            content: cloudNote.content.toString(),
            dateTimeEdited: cloudNote.dateTimeEdited,
            dateTimeCreated: cloudNote.dateTimeCreated,
            isFavorite: cloudNote.isFavorite,
            color: cloudNote.color,
            syncStatus: 'pending',
          )
        : Note(
            title: title,
            content: content,
            dateTimeEdited: now,
            dateTimeCreated: now,
            isFavorite: 0,
            color: color,
            syncStatus: 'pending',
          );

    // 1. Save locally first — UI updates instantly.
    await DatabaseHelper.instance.addNote(note);

    titleController.text = '';
    contentController.text = '';

    if (cloudNote == null) {
      getAllNotes();
      Get.offAllNamed(AppRoute.HOME);
    }

    // 2. Push to cloud in background (fire-and-forget).
    _trySyncNote(note);
  }

  void updateNote(Note note) async {
    note.syncStatus = 'pending';

    // 1. Update locally first.
    await DatabaseHelper.instance.updateNote(note);
    titleController.text = '';
    contentController.text = '';
    getAllNotes();
    Get.offAllNamed(AppRoute.HOME);

    // 2. Push to cloud in background.
    _trySyncNote(note);
  }

  /// Soft-deletes a note (moves it to the recycle bin).
  void deleteNote(int id) async {
    final note = notes.firstWhere((n) => n.id == id, orElse: () => Note(id: id));
    await DatabaseHelper.instance.softDeleteNote(id);

    // Update the in-memory note and sync the soft-delete to cloud
    note.isDeleted = 1;
    note.deletedAt = DateTime.now().toUtc().toIso8601String();
    note.syncStatus = 'pending';
    _trySyncNote(note);

    getAllNotes();
  }

  Future<void> updateNoteColor(int id, String color) async {
    final note = notes.firstWhere((n) => n.id == id);
    note.color = color;
    note.syncStatus = 'pending';
    await DatabaseHelper.instance.updateNote(note);
    getAllNotes();
    _trySyncNote(note);
  }

  void favoriteNote(int id) async {
    final note = notes.firstWhere((n) => n.id == id);
    note.isFavorite = note.isFavorite == 1 ? 0 : 1;
    note.syncStatus = 'pending';
    await DatabaseHelper.instance.updateNote(note);
    getAllNotes();
    _trySyncNote(note);
  }

  /// Soft-deletes all active notes (moves them to the recycle bin).
  Future<void> deleteAllNotes() async {
    // Sync soft-delete for cloud-synced notes
    for (final note in notes) {
      note.isDeleted = 1;
      note.deletedAt = DateTime.now().toUtc().toIso8601String();
      note.syncStatus = 'pending';
      _trySyncNote(note);
    }
    await DatabaseHelper.instance.softDeleteAllNotes();
    getAllNotes();
  }

  Future<void> getAllNotes() async {
    final list = await DatabaseHelper.instance.getNoteList();
    
    list.sort((a, b) {
      final aDate = _sortBy == 'edited' ? a.editedDateTime : a.createdDateTime;
      final bDate = _sortBy == 'edited' ? b.editedDateTime : b.createdDateTime;
      
      if (_sortOrder == 'desc') {
        return bDate.compareTo(aDate);
      } else {
        return aDate.compareTo(bDate);
      }
    });

    notes = list;
    update();
  }

  void shareNote(String content) {
    SharePlus.instance.share(ShareParams(text: content));
  }

  // ── Recycle Bin ──────────────────────────────────────────────────────────

  /// Loads trashed notes from the database.
  Future<void> getAllDeletedNotes() async {
    deletedNotes = await DatabaseHelper.instance.getDeletedNotes();
    update();
  }

  /// Restores a single note from the recycle bin back to the active list.
  Future<void> restoreNote(int id) async {
    await DatabaseHelper.instance.restoreNote(id);

    // Find the note in the deleted list and sync the restore to cloud
    final note = deletedNotes.firstWhereOrNull((n) => n.id == id);
    if (note != null) {
      note.isDeleted = 0;
      note.deletedAt = null;
      note.syncStatus = 'pending';
      _trySyncNote(note);
    }

    getAllNotes();
    getAllDeletedNotes();
  }

  /// Restores multiple notes from the recycle bin.
  Future<void> restoreSelectedNotes() async {
    final idsToRestore = selectedIds.toList();
    selectedIds.clear();
    await DatabaseHelper.instance.restoreNotesByIds(idsToRestore);

    // Sync each restored note to cloud
    final notesToSync = deletedNotes.where((n) => idsToRestore.contains(n.id)).toList();
    for (final note in notesToSync) {
      note.isDeleted = 0;
      note.deletedAt = null;
      note.syncStatus = 'pending';
      _trySyncNote(note);
    }

    getAllNotes();
    getAllDeletedNotes();
  }

  /// Permanently deletes a single note from the recycle bin.
  Future<void> permanentlyDeleteNote(int id) async {
    final note = deletedNotes.firstWhere((n) => n.id == id, orElse: () => Note(id: id));
    await _deleteNoteWithSync(note);
    getAllDeletedNotes();
  }

  /// Permanently deletes selected notes from the recycle bin.
  Future<void> permanentlyDeleteSelectedNotes() async {
    final idsToDelete = selectedIds.toList();
    selectedIds.clear();

    final notesToDelete = deletedNotes.where((n) => idsToDelete.contains(n.id)).toList();
    for (final note in notesToDelete) {
      await _deleteNoteWithSync(note);
    }
    getAllDeletedNotes();
  }

  /// Permanently deletes all notes in the recycle bin.
  Future<void> emptyTrash() async {
    // Delete cloud copies first
    for (final note in deletedNotes) {
      if (note.cloudId != null) {
        try {
          await Get.find<SyncService>().pushNote(
            note..syncStatus = 'pendingDelete',
            _getLoggedInEmail() ?? '',
          );
        } catch (e) {
          print('[NoteController] Cloud delete failed for trashed note ${note.id}: $e');
        }
      }
    }
    // Then remove all from local DB
    await DatabaseHelper.instance.emptyTrash();
    getAllDeletedNotes();
  }

  /// Auto-purges notes that have been in the trash for more than 30 days.
  /// Called on app startup.
  Future<void> purgeExpiredTrash() async {
    final expired = await DatabaseHelper.instance.getExpiredTrashNotes(30);
    for (final note in expired) {
      await _deleteNoteWithSync(note);
    }
    if (expired.isNotEmpty) {
      print('[NoteController] Auto-purged ${expired.length} expired trashed note(s).');
    }
  }

  // ── Sync helpers ─────────────────────────────────────────────────────────

  /// Attempts to sync [note] to Appwrite if the user is logged in.
  /// Silently fails — the note stays 'pending' and will be retried next sync.
  void _trySyncNote(Note note) async {
    final email = _getLoggedInEmail();
    if (email == null) return;
    try {
      await Get.find<SyncService>().pushNote(note, email);
      // Refresh list to show updated syncStatus.
      getAllNotes();
    } catch (e) {
      print('[NoteController] Background sync failed for note ${note.id}: $e');
    }
  }

  /// Deletes a note locally and marks it for cloud deletion.
  Future<void> _deleteNoteWithSync(Note note) async {
    if (note.cloudId != null) {
      // If it has a cloud counterpart, try to delete it too.
      try {
        await Get.find<SyncService>().pushNote(
          note..syncStatus = 'pendingDelete',
          _getLoggedInEmail() ?? '',
        );
        return; // SyncService.pushNote handles local deletion in this case.
      } catch (e) {
        print('[NoteController] Cloud delete failed for note ${note.id}: $e');
      }
    }
    // Fall back to local-only delete.
    await DatabaseHelper.instance.deleteNote(note);
  }

  String? _getLoggedInEmail() {
    final email = sharedPreferences.getString(AppConstants.authKey);
    return (email != null && email.isNotEmpty) ? email : null;
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
    if (status) {
      // Disable biometric lock when PIN lock is enabled (one lock at a time)
      await sharedPreferences.setBool(AppConstants.biometricLockActiveKey, false);
    }
    update();
    return sharedPreferences.setBool(AppConstants.passActiveKey, status);
  }

  bool isBiometricEnabled() =>
      sharedPreferences.getBool(AppConstants.biometricKey) ?? false;

  Future<void> setBiometricEnabled(bool status) async {
    await sharedPreferences.setBool(AppConstants.biometricKey, status);
    update();
  }

  bool isBiometricLockActive() =>
      sharedPreferences.getBool(AppConstants.biometricLockActiveKey) ?? false;

  // Tracks whether the user has authenticated in the current foreground session.
  // Prevents the lifecycle observer from re-locking immediately after auth.
  bool _sessionUnlocked = false;
  bool get isSessionUnlocked => _sessionUnlocked;
  void setSessionUnlocked(bool value) => _sessionUnlocked = value;

  Future<void> setBiometricLockActive(bool status) async {
    await sharedPreferences.setBool(AppConstants.biometricLockActiveKey, status);
    if (status) {
      // Disable PIN lock when biometric lock is enabled (one lock at a time)
      await sharedPreferences.setBool(AppConstants.passActiveKey, false);
      await sharedPreferences.setBool(AppConstants.biometricKey, false);
      appLockStatus = false;
    }
    update();
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

  void changeLayout(int index) {
    _layoutIndex = index;
    sharedPreferences.setInt(AppConstants.layoutKey, index);
    update();
  }

  void changeCardDesign(int index) {
    _cardDesignIndex = index;
    sharedPreferences.setInt('card_design', index);
    update();
  }

  void _loadCurrentTheme() {
    _darkTheme = sharedPreferences.getBool(AppConstants.theme) ?? false;
    _currentFont = sharedPreferences.getString(AppConstants.fontKey) ?? 'Inter';
    _layoutIndex = sharedPreferences.getInt(AppConstants.layoutKey) ?? 0;
    _cardDesignIndex = sharedPreferences.getInt('card_design') ?? 0;
    update();
  }

  void _loadSortPreferences() {
    _sortBy = sharedPreferences.getString('sort_by') ?? 'edited';
    _sortOrder = sharedPreferences.getString('sort_order') ?? 'desc';
  }

  void changeSortOption(String by, String order) {
    _sortBy = by;
    _sortOrder = order;
    sharedPreferences.setString('sort_by', by);
    sharedPreferences.setString('sort_order', order);
    getAllNotes();
  }
}
