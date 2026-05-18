import 'dart:async';
import 'dart:io';

import 'package:my_note_app/model/note_model.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  late Database _database;

  static const _dbName = "notes.db";
  static const _dbVersion = 2; // bumped: added cloudId, syncStatus columns
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
      onUpgrade: _onUpgrade,
    );
  }

  void _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName(
        note_id INTEGER PRIMARY KEY,
        cloudId TEXT,
        syncStatus TEXT NOT NULL DEFAULT 'synced',
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        dateTimeEdited TEXT NOT NULL,
        dateTimeCreated TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        color TEXT NOT NULL
      )
      ''');
  }

  /// Migrate existing installs to schema v2 — safely adds new columns.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE $_tableName ADD COLUMN cloudId TEXT");
      await db.execute(
          "ALTER TABLE $_tableName ADD COLUMN syncStatus TEXT NOT NULL DEFAULT 'synced'");
    }
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

  /// Update Note
  Future<int> updateNote(Note note) async {
    print('=====sss===> ${note.toJson()}');
    Database db = await instance.database;
    return await db.update(
      _tableName,
      note.toJson(),
      where: "note_id = ?",
      whereArgs: [note.id],
    );
  }

  Future<List<Note>> getNoteList() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query(_tableName, orderBy: 'dateTimeCreated DESC');
    return List.generate(
      maps.length,
      (index) {
        return Note(
          id: maps[index]['note_id'],
          cloudId: maps[index]['cloudId'] as String?,
          syncStatus: maps[index]['syncStatus'] as String? ?? 'synced',
          title: maps[index]['title'],
          content: maps[index]['content'],
          dateTimeEdited: maps[index]['dateTimeEdited'],
          dateTimeCreated: maps[index]['dateTimeCreated'],
          isFavorite: maps[index]['isFavorite'],
          color: maps[index]['color'],
        );
      },
    );
  }

  /// Fetch only notes that haven't been synced to the cloud yet.
  Future<List<Note>> getPendingNotes() async {
    final db = await instance.database;
    final maps = await db.query(
      _tableName,
      where: "syncStatus = ? OR syncStatus = ?",
      whereArgs: ['pending', 'pendingDelete'],
    );
    return maps
        .map((m) => Note(
              id: m['note_id'] as int?,
              cloudId: m['cloudId'] as String?,
              syncStatus: m['syncStatus'] as String?,
              title: m['title'] as String?,
              content: m['content'] as String?,
              dateTimeEdited: m['dateTimeEdited'] as String?,
              dateTimeCreated: m['dateTimeCreated'] as String?,
              isFavorite: m['isFavorite'] as int?,
              color: m['color'] as String?,
            ))
        .toList();
  }

  /// Update only cloudId and syncStatus after a successful cloud push.
  Future<void> updateCloudSync({
    required int localId,
    required String cloudId,
    required String syncStatus,
  }) async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {'cloudId': cloudId, 'syncStatus': syncStatus},
      where: 'note_id = ?',
      whereArgs: [localId],
    );
  }

  /// Mark a note by its cloudId for deletion (soft delete for sync).
  Future<void> markPendingDelete(String cloudId) async {
    final db = await instance.database;
    await db.update(
      _tableName,
      {'syncStatus': 'pendingDelete'},
      where: 'cloudId = ?',
      whereArgs: [cloudId],
    );
  }

  /// Check if a note with the given cloudId already exists locally.
  Future<Note?> getNoteByCloudId(String cloudId) async {
    final db = await instance.database;
    final maps = await db.query(
      _tableName,
      where: 'cloudId = ?',
      whereArgs: [cloudId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    return Note(
      id: m['note_id'] as int?,
      cloudId: m['cloudId'] as String?,
      syncStatus: m['syncStatus'] as String?,
      title: m['title'] as String?,
      content: m['content'] as String?,
      dateTimeEdited: m['dateTimeEdited'] as String?,
      dateTimeCreated: m['dateTimeCreated'] as String?,
      isFavorite: m['isFavorite'] as int?,
      color: m['color'] as String?,
    );
  }
}
