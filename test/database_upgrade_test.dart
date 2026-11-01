import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/database_helper/database_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _v1Columns = '''
  note_id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  dateTimeEdited TEXT NOT NULL,
  dateTimeCreated TEXT NOT NULL,
  isFavorite INTEGER NOT NULL DEFAULT 0,
  color TEXT NOT NULL
''';
const _v2Columns = '''$_v1Columns,
  cloudId TEXT,
  syncStatus TEXT NOT NULL DEFAULT 'synced'
''';
const _v3Columns = '''$_v2Columns,
  isDeleted INTEGER NOT NULL DEFAULT 0,
  deletedAt TEXT
''';

const _userFields = {
  'title': 'Shopping',
  'content': '[{"insert":"milk\\n"}]',
  'dateTimeEdited': '31-10-2026 02:30 PM',
  'dateTimeCreated': '01-01-2025 09:00 AM',
  'isFavorite': 1,
  'color': '#FF112233',
};

Future<Database> _openOld(int version, String columns, void Function(Batch) seed) async {
  final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false));
  await db.execute('CREATE TABLE notes($columns)');
  final batch = db.batch();
  seed(batch);
  await batch.commit();
  await DatabaseHelper.upgradeSchema(db, version, 5);
  return db;
}

void _expectUserFieldsUnchanged(Map<String, Object?> row) {
  _userFields.forEach((key, value) => expect(row[key], value, reason: key));
}

void main() {
  setUpAll(sqfliteFfiInit);

  test('v1 notes keep every field and are queued for upload', () async {
    final db = await _openOld(1, _v1Columns, (b) => b.insert('notes', _userFields));
    final row = (await db.query('notes')).single;

    _expectUserFieldsUnchanged(row);
    expect(row['syncStatus'], 'pending');
    expect(row['isDeleted'], 0);
    expect(row['syncId'], isNotNull);
    expect(row['cloudId'], isNull);
    await db.close();
  });

  test('v2 notes upgrade the same way', () async {
    final db = await _openOld(2, _v2Columns, (b) {
      b.insert('notes', {..._userFields, 'cloudId': 'abc', 'syncStatus': 'synced'});
    });
    final row = (await db.query('notes')).single;

    _expectUserFieldsUnchanged(row);
    expect(row['cloudId'], isNull);
    expect(row['syncStatus'], 'pending');
    await db.close();
  });

  test('v3 notes keep trash state, and old links are cleared', () async {
    final db = await _openOld(3, _v3Columns, (b) {
      b.insert('notes', {
        ..._userFields,
        'cloudId': 'abc',
        'syncStatus': 'synced',
        'isDeleted': 1,
        'deletedAt': '2026-10-01T00:00:00.000Z',
      });
    });
    final row = (await db.query('notes')).single;

    _expectUserFieldsUnchanged(row);
    expect(row['isDeleted'], 1);
    expect(row['deletedAt'], '2026-10-01T00:00:00.000Z');
    expect(row['cloudId'], isNull);
    expect(row['remoteVersion'], isNull);
    expect(row['syncStatus'], 'pending');
    await db.close();
  });

  test('updatedAt comes from the existing edit date, in legacy and ISO formats', () async {
    final db = await _openOld(3, _v3Columns, (b) {
      b.insert('notes', _userFields);
      b.insert('notes', {..._userFields, 'dateTimeEdited': '2026-05-01T10:00:00.000Z'});
    });
    final rows = await db.query('notes', orderBy: 'note_id');

    expect(rows[0]['updatedAt'], Note.parseDate('31-10-2026 02:30 PM')!.millisecondsSinceEpoch);
    expect(rows[1]['updatedAt'], DateTime.utc(2026, 5, 1, 10).millisecondsSinceEpoch);
    await db.close();
  });

  test('the same Appwrite note on two devices gets the same syncId', () async {
    Future<Object?> upgradeDevice() async {
      final db = await _openOld(3, _v3Columns, (b) {
        b.insert('notes', {..._userFields, 'cloudId': 'shared-id'});
      });
      final id = (await db.query('notes')).single['syncId'];
      await db.close();
      return id;
    }

    expect(await upgradeDevice(), await upgradeDevice());
  });

  test('notes that never reached the cloud get different syncIds', () async {
    final db = await _openOld(3, _v3Columns, (b) {
      b.insert('notes', _userFields);
      b.insert('notes', _userFields);
    });
    final rows = await db.query('notes');
    expect(rows[0]['syncId'], isNot(rows[1]['syncId']));
    await db.close();
  });

  test('a real v3 database file upgrades through sqflite on open', () async {
    final dir = await Directory.systemTemp.createTemp('note_upgrade_test');
    final path = '${dir.path}/notes.db';
    final old = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) => db.execute('CREATE TABLE notes($_v3Columns)'),
      ),
    );
    await old.insert('notes', {..._userFields, 'cloudId': 'abc'});
    await old.close();

    final db = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(version: 4, onUpgrade: DatabaseHelper.upgradeSchema),
    );
    final row = (await db.query('notes')).single;

    expect(await db.getVersion(), 4);
    _expectUserFieldsUnchanged(row);
    expect(row['syncId'], isNotNull);
    expect(row['syncStatus'], 'pending');
    await db.close();
  });

  test('v4 notes get a sync base only if they match Drive', () async {
    final db = await _openOld(3, _v3Columns, (b) => b.insert('notes', _userFields));
    await db.update('notes', {'syncBase': null, 'syncStatus': 'synced'});
    await db.execute('ALTER TABLE notes RENAME COLUMN syncBase TO oldBase');
    await db.insert('notes', {..._userFields, 'syncStatus': 'pending'});

    await DatabaseHelper.upgradeSchema(db, 4, 5);

    final rows = await db.query('notes', orderBy: 'note_id');
    expect(rows[0]['syncBase'], Note.fromJson(rows[0]).syncState);
    expect(rows[1]['syncBase'], isNull);
    _expectUserFieldsUnchanged(rows[0]);
  });

  test('rows already waiting for deletion are not kept', () async {
    final db = await _openOld(3, _v3Columns, (b) {
      b.insert('notes', {..._userFields, 'cloudId': 'x', 'syncStatus': 'pendingDelete'});
      b.insert('notes', _userFields);
    });
    expect(await db.query('notes'), hasLength(1));
    await db.close();
  });
}
