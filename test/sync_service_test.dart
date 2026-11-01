import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_note_app/database_helper/database_helper.dart';
import 'package:my_note_app/drive/drive_repository.dart';
import 'package:my_note_app/helper/note_image_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/services/sync_merge.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String path;
  FakePathProvider(this.path);
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

/// In-memory Drive. Clearing the database simulates a second device.
class FakeDrive extends DriveRepository {
  FakeDrive() : super(clientProvider: ({bool forceRefresh = false}) => throw UnimplementedError());

  final Map<String, RemoteFile> files = {};
  final Map<String, List<int>> contents = {};
  int _nextId = 0;
  int creates = 0;
  int updates = 0;
  int running = 0;
  int maxRunning = 0;
  Exception? failDeletes;
  Exception? failCreates;
  Exception? failLists;
  Completer<void>? holdList;
  Exception? failDownloads;
  Completer<void>? holdDownload;
  Set<String> hiddenFromList = {};
  void Function()? afterList;

  @override
  Future<List<RemoteFile>> listFiles() async {
    if (failLists != null) throw failLists!;
    running++;
    if (running > maxRunning) maxRunning = running;
    await holdList?.future;
    running--;
    final listed = files.values.where((f) => !hiddenFromList.contains(f.id)).toList();
    afterList?.call();
    afterList = null;
    return listed;
  }

  @override
  Future<Map<String, dynamic>> downloadJson(String fileId) async {
    if (failDownloads != null) throw failDownloads!;
    await holdDownload?.future;
    return jsonDecode(utf8.decode(contents[fileId]!)) as Map<String, dynamic>;
  }

  @override
  Future<String?> getVersion(String fileId) async => files[fileId]?.version;

  /// Drive raises a file's version for changes that aren't edits to its text.
  void bumpVersion(String fileId) {
    final file = files[fileId]!;
    files[fileId] = RemoteFile(
      id: file.id,
      name: file.name,
      version: '${int.parse(file.version) + 1}',
      modifiedTime: DateTime.now(),
    );
  }

  /// Simulates another device saving its version of a note to Drive.
  void writeFromOtherDevice(Note row, Map<String, dynamic> changes) {
    contents[row.cloudId!] = utf8.encode(jsonEncode({...row.toDriveJson(), ...changes}));
    bumpVersion(row.cloudId!);
  }

  @override
  Future<List<int>> downloadBytes(String fileId) async => contents[fileId]!;

  @override
  Future<RemoteFile> createJson(String name, Map<String, dynamic> data) =>
      createBytes(name, utf8.encode(jsonEncode(data)), 'application/json');

  @override
  Future<RemoteFile> createBytes(String name, List<int> bytes, String contentType) async {
    if (failCreates != null) throw failCreates!;
    creates++;
    final id = 'file${_nextId++}';
    contents[id] = bytes;
    return files[id] = RemoteFile(id: id, name: name, version: '1', modifiedTime: DateTime.now());
  }

  @override
  Future<RemoteFile> updateJson(String fileId, Map<String, dynamic> data) async {
    final existing = files[fileId];
    if (existing == null) throw DriveFileNotFound();
    updates++;
    contents[fileId] = utf8.encode(jsonEncode(data));
    return files[fileId] = RemoteFile(
      id: fileId,
      name: existing.name,
      version: '${int.parse(existing.version) + 1}',
      modifiedTime: DateTime.now(),
    );
  }

  @override
  Future<void> deleteFile(String fileId) async {
    if (failDeletes != null) throw failDeletes!;
    files.remove(fileId);
    contents.remove(fileId);
  }

  @override
  void endSession() {}

  Map<String, dynamic> noteJson(String syncId) {
    final file = files.values.firstWhere((f) => f.name == noteFileName(syncId));
    return jsonDecode(utf8.decode(contents[file.id]!)) as Map<String, dynamic>;
  }

  List<RemoteFile> get noteFiles =>
      files.values.where((f) => syncIdFromFileName(f.name) != null).toList();
}

final _db = DatabaseHelper.instance;

Note _note(String content, {int isDeleted = 0, int favorite = 0}) => Note(
      title: 'title',
      content: content,
      dateTimeEdited: '31-10-2026 10:00 AM',
      dateTimeCreated: '30-10-2026 09:00 AM',
      isFavorite: favorite,
      color: '#FF112233',
      syncStatus: 'pending',
      isDeleted: isDeleted,
      deletedAt: isDeleted == 1 ? '2026-10-31T00:00:00.000Z' : null,
    );

Future<Note> _row(String syncId) async =>
    (await _db.getAllNotesForSync()).firstWhere((n) => n.syncId == syncId);

void main() {
  late FakeDrive drive;
  late SyncService sync;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('note_sync_test');
    PathProviderPlatform.instance = FakePathProvider(dir.path);
    await NoteImageHelper.init();
  });

  setUp(() async {
    await _db.deleteAllNotes();
    await NoteImageHelper.deleteAll();
    drive = FakeDrive();
    sync = SyncService(repository: drive, isLoggedIn: () => true);
  });

  test('login uploads all local notes including trash, and resync uploads nothing', () async {
    await _db.addNote(_note('active', favorite: 1));
    await _db.addNote(_note('trashed', isDeleted: 1));

    await sync.syncNow();

    expect(sync.syncStatus, 'done');
    expect(drive.creates, 2);
    final notes = await _db.getAllNotesForSync();
    expect(notes.every((n) => n.syncStatus == 'synced' && n.cloudId != null), isTrue);
    final trashed = notes.firstWhere((n) => n.content == 'trashed');
    expect(drive.noteJson(trashed.syncId!)['isDeleted'], 1);

    drive.creates = 0;
    await sync.syncNow();
    expect(drive.creates, 0);
    expect(drive.updates, 0);
  });

  test('a second device downloads notes with every field intact', () async {
    final note = _note('shared', favorite: 1);
    await _db.addNote(note);
    await sync.syncNow();

    await _db.deleteAllNotes();
    await sync.syncNow();

    final row = await _row(note.syncId!);
    expect(row.content, 'shared');
    expect(row.isFavorite, 1);
    expect(row.color, '#FF112233');
    expect(row.dateTimeEdited, '31-10-2026 10:00 AM');
    expect(row.dateTimeCreated, '30-10-2026 09:00 AM');
    expect(row.syncStatus, 'synced');
  });

  test('upload retried after a lost response makes no duplicate', () async {
    final note = _note('text');
    await _db.addNote(note);
    await sync.syncNow();

    // The Drive file exists but this device never recorded the response.
    await _db.markForReupload([note.id!]);
    drive.creates = 0;
    await sync.syncNow();

    expect(drive.creates, 0);
    expect(drive.noteFiles, hasLength(1));
    expect(await _db.getAllNotesForSync(), hasLength(1));
  });

  test('a failed cloud delete stays queued and the note does not come back', () async {
    final note = _note('text');
    await _db.addNote(note);
    await sync.syncNow();

    await _db.markPendingDelete(note.id!);
    drive.failDeletes = Exception('offline');
    await sync.syncNow();

    expect(sync.syncStatus, 'error');
    expect((await _row(note.syncId!)).syncStatus, 'pendingDelete');

    drive.failDeletes = null;
    await sync.syncNow();
    expect(await _db.getAllNotesForSync(), isEmpty);
    expect(drive.noteFiles, isEmpty);
  });

  test('concurrent requests run one at a time', () async {
    await _db.addNote(_note('text'));
    drive.holdList = Completer<void>();

    final first = sync.syncNow();
    final second = sync.syncNow();
    final third = sync.syncNow();
    drive.holdList!.complete();
    await Future.wait([first, second, third]);

    expect(drive.maxRunning, 1);
    expect(drive.creates, 1);
  });

  test('an edit made during an upload stays pending', () async {
    final note = _note('old');
    await _db.addNote(note);
    await _db.markUploaded(
      localId: note.id!,
      cloudId: 'f',
      remoteVersion: '1',
      uploadedUpdatedAt: note.updatedAt! - 1,
      syncBase: 'base',
    );
    expect((await _row(note.syncId!)).syncStatus, 'pending');
  });

  test('a user edit does not lose the Drive link held only by the row', () async {
    final note = _note('old');
    await _db.addNote(note);
    await sync.syncNow();

    // A screen opened before the upload holds a Note with no cloudId.
    await _db.updateNote(Note(
      id: note.id,
      title: 'title',
      content: 'edited',
      dateTimeEdited: note.dateTimeEdited,
      dateTimeCreated: note.dateTimeCreated,
      isFavorite: 0,
      color: note.color,
    ));
    drive.creates = 0;
    await sync.syncNow();

    expect(drive.creates, 0);
    expect(drive.noteJson(note.syncId!)['content'], 'edited');
  });

  test('favorite and trash changes reach Drive', () async {
    final note = _note('text');
    await _db.addNote(note);
    await sync.syncNow();

    final row = await _row(note.syncId!);
    row.isFavorite = 1;
    await _db.updateNote(row);
    await sync.syncNow();
    expect(drive.noteJson(note.syncId!)['isFavorite'], 1);

    await _db.softDeleteNote(note.id!);
    await sync.syncNow();
    expect(drive.noteJson(note.syncId!)['isDeleted'], 1);
  });

  test('Drive wiped from settings: local notes survive and upload again', () async {
    await _db.addNote(_note('keep me'));
    await sync.syncNow();

    drive.files.clear();
    drive.contents.clear();
    await sync.syncNow();

    final notes = await _db.getAllNotesForSync();
    expect(notes.single.content, 'keep me');
    expect(notes.single.syncStatus, 'synced');
    expect(drive.noteFiles, hasLength(1));
  });

  test('missing Drive access leaves notes pending and prompts once', () async {
    await _db.addNote(_note('text'));
    var prompts = 0;
    sync.onDriveAccessNeeded = () => prompts++;
    drive.failLists = DriveAuthRequired();

    await sync.syncNow();
    await sync.syncNow();

    expect(sync.syncStatus, 'needsDriveAccess');
    expect(prompts, 1);
    expect((await _db.getAllNotesForSync()).single.syncStatus, 'pending');
  });

  test('a full Drive keeps notes pending and reports it', () async {
    await _db.addNote(_note('text'));
    drive.failCreates = DriveQuotaExceeded();

    await sync.syncNow();

    expect(sync.syncStatus, 'quotaFull');
    expect((await _db.getAllNotesForSync()).single.syncStatus, 'pending');
  });

  test('a conflict keeps both versions', () async {
    final note = _note('base');
    await _db.addNote(note);
    await sync.syncNow();

    // Another device uploaded newer text while this device edited offline.
    final row = await _row(note.syncId!);
    await _db.updateNote(row..content = 'mine');
    await drive.updateJson(row.cloudId!, {
      ...row.toDriveJson(),
      'content': 'theirs',
      'updatedAt': row.updatedAt! + 1000,
    });

    await sync.syncNow();

    final contents = (await _db.getAllNotesForSync()).map((n) => n.content).toList();
    expect(contents, hasLength(2));
    expect(contents, contains('theirs'));
    expect(contents.where((c) => c!.contains('mine')), hasLength(1));
    expect(drive.noteFiles, hasLength(2));
  });

  group('no false conflicts or lost changes', () {
    Future<Note> uploaded(String content) async {
      final note = _note(content);
      await _db.addNote(note);
      await sync.syncNow();
      return _row(note.syncId!);
    }

    test('a Drive version bump with no text change makes no conflict copy', () async {
      final row = await uploaded('base');
      drive.bumpVersion(row.cloudId!);
      await _db.updateNote(row..content = 'mine');

      await sync.syncNow();

      final notes = await _db.getAllNotesForSync();
      expect(notes.single.content, 'mine');
      expect(notes.single.syncStatus, 'synced');
      expect(drive.noteJson(row.syncId!)['content'], 'mine');
    });

    test('a favorite here and a text edit elsewhere merge with no copy', () async {
      final row = await uploaded('base');
      drive.writeFromOtherDevice(row, {'content': 'theirs', 'updatedAt': row.updatedAt! + 1000});
      await _db.updateNote(row..isFavorite = 1);

      await sync.syncNow();

      final merged = (await _db.getAllNotesForSync()).single;
      expect(merged.content, 'theirs');
      expect(merged.isFavorite, 1);
      expect(drive.noteJson(row.syncId!)['content'], 'theirs');
      expect(drive.noteJson(row.syncId!)['isFavorite'], 1);
    });

    test('a text edit here and a color change elsewhere merge with no copy', () async {
      final row = await uploaded('base');
      await _db.updateNote(row..content = 'mine');
      drive.writeFromOtherDevice(row, {
        'content': 'base',
        'color': '#FF445566',
        'updatedAt': row.updatedAt! + 1000,
      });

      await sync.syncNow();

      final merged = (await _db.getAllNotesForSync()).single;
      expect(merged.content, 'mine');
      expect(merged.color, '#FF445566');
      expect(drive.noteJson(row.syncId!)['content'], 'mine');
    });

    test('a failed conflict download does not overwrite the Drive edit', () async {
      final row = await uploaded('base');
      await _db.updateNote(row..content = 'mine');
      drive.writeFromOtherDevice(row, {'content': 'theirs', 'updatedAt': row.updatedAt! + 1000});

      drive.failDownloads = Exception('offline');
      await sync.syncNow();
      expect(drive.noteJson(row.syncId!)['content'], 'theirs');
      expect(sync.syncStatus, 'error');

      drive.failDownloads = null;
      await sync.syncNow();
      final contents = (await _db.getAllNotesForSync()).map((n) => n.content).toList();
      expect(contents, contains('theirs'));
      expect(contents.where((c) => c!.contains('mine')), hasLength(1));
    });

    test('Drive changing after the listing is merged, not overwritten', () async {
      final row = await uploaded('base');
      await _db.updateNote(row..content = 'mine');
      drive.afterList = () => drive.writeFromOtherDevice(
          row, {'content': 'theirs', 'updatedAt': row.updatedAt! + 1000});

      await sync.syncNow();

      final contents = (await _db.getAllNotesForSync()).map((n) => n.content).toList();
      expect(contents, contains('theirs'));
      expect(contents.where((c) => c!.contains('mine')), hasLength(1));
    });

    test('an edit made while a conflict downloads is not overwritten', () async {
      final row = await uploaded('base');
      await _db.updateNote(row..content = 'first edit');
      drive.writeFromOtherDevice(row, {'content': 'theirs', 'updatedAt': row.updatedAt! + 1000});

      final hold = drive.holdDownload = Completer<void>();
      final run = sync.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await _db.updateNote((await _row(row.syncId!))..content = 'second edit');
      hold.complete();
      await run;
      drive.holdDownload = null;
      await sync.syncNow();

      final contents = (await _db.getAllNotesForSync()).map((n) => n.content).toList();
      expect(contents.where((c) => c!.contains('second edit')), hasLength(1));
      expect(contents, contains('theirs'));
    });

    test('a note missing from a late listing is kept while its file exists', () async {
      final kept = await uploaded('kept');
      await uploaded('other');
      drive.hiddenFromList = {kept.cloudId!};

      await sync.syncNow();

      expect((await _db.getAllNotesForSync()).map((n) => n.content), contains('kept'));
    });

    test('a note is removed once its Drive file is really gone', () async {
      final gone = await uploaded('gone');
      await uploaded('other');
      await drive.deleteFile(gone.cloudId!);

      await sync.syncNow();

      expect((await _db.getAllNotesForSync()).map((n) => n.content), isNot(contains('gone')));
    });

    test('a note open on screen is not changed until it is released', () async {
      final row = await uploaded('base');
      drive.writeFromOtherDevice(row, {'content': 'theirs', 'updatedAt': row.updatedAt! + 1000});

      sync.holdNote(row.id!);
      await sync.syncNow();
      expect((await _row(row.syncId!)).content, 'base');

      sync.releaseNote(row.id!);
      await sync.syncNow();
      expect((await _row(row.syncId!)).content, 'theirs');
    });

    test('saving an open note made stale by Drive keeps both versions', () async {
      final row = await uploaded('base');
      sync.holdNote(row.id!);
      drive.writeFromOtherDevice(row, {'content': 'theirs', 'updatedAt': row.updatedAt! + 1000});
      await sync.syncNow();

      await _db.updateNote((await _row(row.syncId!))..content = 'mine');
      await sync.syncNow();
      expect(drive.noteJson(row.syncId!)['content'], 'theirs');

      sync.releaseNote(row.id!);
      await sync.syncNow();
      final contents = (await _db.getAllNotesForSync()).map((n) => n.content).toList();
      expect(contents, hasLength(2));
      expect(contents.where((c) => c!.contains('mine')), hasLength(1));
      expect(contents, contains('theirs'));
    });

    test('a favorite saved from a stale list keeps the newer text', () async {
      final stale = await uploaded('base');
      await _db.updateNote((await _row(stale.syncId!))..content = 'newer');

      await _db.updateNoteFields(stale.id!, {'isFavorite': 1});

      final row = await _row(stale.syncId!);
      expect(row.content, 'newer');
      expect(row.isFavorite, 1);
      expect(row.syncStatus, 'pending');
    });

    test('two notes added at the same moment both save', () async {
      await Future.wait([_db.addNote(_note('a')), _db.addNote(_note('b'))]);
      expect(await _db.getAllNotesForSync(), hasLength(2));
    });
  });

  group('images', () {
    String embed(String path) => jsonEncode([
          {
            'insert': {'image': '$path?w=300'}
          },
          {'insert': '\n'},
        ]);

    test('an old absolute-path image moves to app storage and syncs to a new device', () async {
      final source = File('${Directory.systemTemp.createTempSync().path}/picked.jpg')
        ..writeAsBytesSync([1, 2, 3]);
      final note = _note(embed(source.path));
      await _db.addNote(note);

      await sync.syncNow();

      final row = await _row(note.syncId!);
      expect(row.content, contains('note_images/'));
      expect(row.content, contains('?w=300'));
      expect(drive.files.values.where((f) => f.name.startsWith('img_')), hasLength(1));

      final image = NoteImageHelper.referencedImages(row.content).single;
      await NoteImageHelper.deleteAll();
      await _db.deleteAllNotes();
      await sync.syncNow();

      expect(await NoteImageHelper.read(image), [1, 2, 3]);
    });

    test('a missing old image does not block the note text', () async {
      final note = _note(embed('/gone/picked.jpg'));
      await _db.addNote(note);

      await sync.syncNow();

      expect(sync.syncStatus, 'done');
      final row = await _row(note.syncId!);
      expect(row.syncStatus, 'synced');
      expect(row.content, contains('/gone/picked.jpg'));
    });

    test('images used by a note are kept, and old unused ones are removed', () async {
      final path = await NoteImageHelper.importPicked(
        (File('${Directory.systemTemp.createTempSync().path}/a.jpg')..writeAsBytesSync([9])).path,
      );
      await _db.addNote(_note(embed(path)));
      final old = DateTime.now().subtract(const Duration(days: 40));
      drive.files['stale'] = RemoteFile(id: 'stale', name: 'img_stale.jpg', version: '1', modifiedTime: old);
      drive.files['recent'] = RemoteFile(id: 'recent', name: 'img_recent.jpg', version: '1', modifiedTime: DateTime.now());

      await sync.syncNow();

      final names = drive.files.values.map((f) => f.name);
      expect(names, isNot(contains('img_stale.jpg')));
      expect(names, contains('img_recent.jpg'));
      expect(names, contains(NoteImageHelper.driveName(path)));
    });
  });
}
