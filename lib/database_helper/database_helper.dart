import 'dart:async';
import 'dart:io';

import 'package:my_note_app/model/note_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  late Database _database;

  static const _dbName = "notes.db";
  static const _dbVersion = 4; // bumped: added Drive sync columns
  static const _tableName = "notes";

  Future<Database> get database async {
    _database = await initiateDatabase();
    return _database;
  }

  initiateDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, _dbName);
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: upgradeSchema,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        note_id INTEGER PRIMARY KEY,
        syncId TEXT,
        cloudId TEXT,
        remoteVersion TEXT,
        updatedAt INTEGER,
        syncStatus TEXT NOT NULL DEFAULT 'synced',
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        dateTimeEdited TEXT NOT NULL,
        dateTimeCreated TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        color TEXT NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        deletedAt TEXT
      )
      ''');
  }

  /// Migrate existing installs — safely adds new columns.
  static Future<void> upgradeSchema(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE $_tableName ADD COLUMN cloudId TEXT");
      await db.execute(
          "ALTER TABLE $_tableName ADD COLUMN syncStatus TEXT NOT NULL DEFAULT 'synced'");
    }
    if (oldVersion < 3) {
      await db.execute(
          "ALTER TABLE $_tableName ADD COLUMN isDeleted INTEGER NOT NULL DEFAULT 0");
      await db.execute(
          "ALTER TABLE $_tableName ADD COLUMN deletedAt TEXT");
    }
    if (oldVersion < 4) {
      await db.execute("ALTER TABLE $_tableName ADD COLUMN syncId TEXT");
      await db.execute("ALTER TABLE $_tableName ADD COLUMN remoteVersion TEXT");
      await db.execute("ALTER TABLE $_tableName ADD COLUMN updatedAt INTEGER");
      await _prepareNotesForDrive(db);
    }
  }

  /// Prepares notes from the Appwrite era for their first Drive upload without
  /// touching what the user wrote. Only sync bookkeeping columns change.
  static Future<void> _prepareNotesForDrive(Database db) async {
    await db.delete(_tableName, where: "syncStatus = 'pendingDelete'");
    final rows = await db.query(_tableName);
    final batch = db.batch();
    for (final row in rows) {
      final oldCloudId = row['cloudId'] as String?;
      final edited = Note.parseDate(row['dateTimeEdited'] as String?) ??
          Note.parseDate(row['dateTimeCreated'] as String?);
      batch.update(
        _tableName,
        {
          // Derived from the Appwrite id so the same note on two devices gets
          // the same syncId and merges instead of uploading twice.
          'syncId': oldCloudId != null
              ? const Uuid().v5(Namespace.url.value, oldCloudId)
              : const Uuid().v4(),
          'updatedAt': edited?.millisecondsSinceEpoch ?? 0,
          'cloudId': null,
          'remoteVersion': null,
          'syncStatus': 'pending',
        },
        where: 'note_id = ?',
        whereArgs: [row['note_id']],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<int> getNextId() async {
   final db = await instance.database;
   final result = await db.rawQuery('SELECT MAX(note_id) as maxId FROM $_tableName');
   int? maxId = result.first['maxId'] as int?;
  return (maxId ?? 0) + 1;
 }

  /// Add Note
  Future<int> addNote(Note note) async {
    // int newId = await getNextId();
    note.id = await getNextId();
    note.syncId ??= const Uuid().v4();
    note.updatedAt ??= DateTime.now().toUtc().millisecondsSinceEpoch;
    print('=====new id: ${note.id}');
    Database db = await instance.database;
    return await db.insert(_tableName, note.toJson());
  }

  /// Delete Note
  Future<int> deleteNote(Note note) async {
    Database db = await instance.database;
    return await db.delete(
      _tableName,
      where: "note_id = ?",
      whereArgs: [note.id],
    );
  }

  /// Delete All Notes
  Future<int> deleteAllNotes() async {
    Database db = await instance.database;
    return await db.delete(_tableName);
  }

  /// Delete notes by a list of IDs in a single query
  Future<void> deleteNotesByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      _tableName,
      where: 'note_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Update Note after a user change and queue it for upload.
  /// Sync columns are left alone, because the [note] held by a screen can be
  /// older than the row and only the sync code may change them.
  Future<int> updateNote(Note note) async {
    note.updatedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    note.syncStatus = 'pending';
    final values = note.toJson()
      ..remove('syncId')
      ..remove('cloudId')
      ..remove('remoteVersion');
    print('=====sss===>$values');
    Database db = await instance.database;
    return await db.update(
      _tableName,
      values,
      where: "note_id = ?",
      whereArgs: [note.id],
    );
  }

  /// Returns only active (non-deleted) notes.
  Future<List<Note>> getNoteList() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'isDeleted = ?',
      whereArgs: [0],
      orderBy: 'dateTimeCreated DESC',
    );
    return maps.map((m) => Note.fromJson(m)).toList();
  }

  // ── Recycle Bin queries ──────────────────────────────────────────────────

  /// Returns only soft-deleted (trashed) notes, newest trash first.
  Future<List<Note>> getDeletedNotes() async {
    final db = await instance.database;
    final maps = await db.query(
      _tableName,
      where: "isDeleted = ? AND syncStatus != 'pendingDelete'",
      whereArgs: [1],
      orderBy: 'deletedAt DESC',
    );
    return maps.map((m) => Note.fromJson(m)).toList();
  }

  /// Soft-delete a note — moves it to the recycle bin.
  Future<void> softDeleteNote(int noteId) async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
        'syncStatus': 'pending',
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }

  /// Soft-delete multiple notes by IDs.
  Future<void> softDeleteNotesByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      _tableName,
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
        'syncStatus': 'pending',
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'note_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Soft-delete ALL active notes (move all to trash).
  Future<void> softDeleteAllNotes() async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toUtc().toIso8601String(),
        'syncStatus': 'pending',
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'isDeleted = ?',
      whereArgs: [0],
    );
  }

  /// Restore a soft-deleted note back to the active list.
  Future<void> restoreNote(int noteId) async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {
        'isDeleted': 0,
        'deletedAt': null,
        'syncStatus': 'pending',
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }

  /// Restore multiple soft-deleted notes by IDs.
  Future<void> restoreNotesByIds(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      _tableName,
      {
        'isDeleted': 0,
        'deletedAt': null,
        'syncStatus': 'pending',
        'updatedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      },
      where: 'note_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Returns trashed notes older than [days] days.
  Future<List<Note>> getExpiredTrashNotes(int days) async {
    final db = await instance.database;
    final cutoff = DateTime.now().toUtc().subtract(Duration(days: days)).toIso8601String();
    final maps = await db.query(
      _tableName,
      where: "isDeleted = ? AND deletedAt IS NOT NULL AND deletedAt < ? AND syncStatus != 'pendingDelete'",
      whereArgs: [1, cutoff],
    );
    return maps.map((m) => Note.fromJson(m)).toList();
  }

  /// Permanently delete all trashed notes.
  Future<int> emptyTrash() async {
    final db = await instance.database;
    return await db.delete(
      _tableName,
      where: 'isDeleted = ?',
      whereArgs: [1],
    );
  }

  // ── Sync queries ───────────────────────────────────────────────────────

  /// Every row, including trashed notes and rows waiting for cloud deletion.
  Future<List<Note>> getAllNotesForSync() async {
    final db = await instance.database;
    final maps = await db.query(_tableName);
    return maps.map((m) => Note.fromJson(m)).toList();
  }

  /// Fetch only notes that haven't been synced to the cloud yet.
  Future<List<Note>> getPendingNotes() async {
    final db = await instance.database;
    final maps = await db.query(
      _tableName,
      where: "syncStatus = ? OR syncStatus = ?",
      whereArgs: ['pending', 'pendingDelete'],
    );
    return maps.map((m) => Note.fromJson(m)).toList();
  }

  /// Records a successful upload. The note only becomes 'synced' if it hasn't
  /// changed since the upload started, otherwise the newer edit stays pending.
  Future<void> markUploaded({
    required int localId,
    required String cloudId,
    required String remoteVersion,
    required int? uploadedUpdatedAt,
  }) async {
    final db = await instance.database;
    await db.rawUpdate(
      "UPDATE $_tableName SET cloudId = ?, remoteVersion = ?, "
      "syncStatus = CASE WHEN updatedAt IS ? THEN 'synced' ELSE syncStatus END "
      "WHERE note_id = ?",
      [cloudId, remoteVersion, uploadedUpdatedAt, localId],
    );
  }

  /// Replaces a row with the Drive copy, unless the user changed it meanwhile.
  Future<void> overwriteFromRemote(int localId, Note remote) async {
    final db = await instance.database;
    final values = remote.toJson()
      ..remove('note_id')
      ..['syncStatus'] = 'synced';
    await db.update(
      _tableName,
      values,
      where: "note_id = ? AND syncStatus = 'synced'",
      whereArgs: [localId],
    );
  }

  /// Links a row to its Drive file without changing its status or content.
  Future<void> linkRemote(int localId, String cloudId, String remoteVersion) async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {'cloudId': cloudId, 'remoteVersion': remoteVersion},
      where: 'note_id = ?',
      whereArgs: [localId],
    );
  }

  /// Forgets the Drive link of the given notes so they upload again.
  Future<void> markForReupload(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await instance.database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      _tableName,
      {'cloudId': null, 'remoteVersion': null, 'syncStatus': 'pending'},
      where: 'note_id IN ($placeholders)',
      whereArgs: ids,
    );
  }

  /// Forgets every Drive link, for example when the Google account changes.
  Future<void> markAllForReupload() async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {'cloudId': null, 'remoteVersion': null, 'syncStatus': 'pending'},
      where: "syncStatus != 'pendingDelete'",
    );
    await db.delete(
      _tableName,
      where: "syncStatus = 'pendingDelete' AND cloudId IS NULL",
    );
  }

  /// Saves a sync-side content rewrite. updatedAt stays the same on purpose,
  /// because rewriting an image path is not a user edit.
  Future<void> updateContentForSync(int localId, String content) async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {'content': content},
      where: 'note_id = ?',
      whereArgs: [localId],
    );
  }

  /// Applies both sides of a conflict in one transaction, so a crash can't
  /// overwrite the row without also saving the conflict copy.
  Future<void> saveConflict({required Note winner, Note? copy}) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        _tableName,
        winner.toJson()..remove('note_id'),
        where: 'note_id = ?',
        whereArgs: [winner.id],
      );
      if (copy != null) {
        final result = await txn.rawQuery('SELECT MAX(note_id) as maxId FROM $_tableName');
        copy.id = ((result.first['maxId'] as int?) ?? 0) + 1;
        await txn.insert(_tableName, copy.toJson());
      }
    });
  }

  /// Hides a note until sync has removed its Drive file. Keeping the row means
  /// a failed cloud delete is retried instead of the note coming back.
  Future<void> markPendingDelete(int noteId) async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {'syncStatus': 'pendingDelete'},
      where: 'note_id = ?',
      whereArgs: [noteId],
    );
  }

  /// Same as [markPendingDelete] for everything in the recycle bin.
  Future<void> markTrashPendingDelete() async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {'syncStatus': 'pendingDelete'},
      where: 'isDeleted = ?',
      whereArgs: [1],
    );
  }
}
