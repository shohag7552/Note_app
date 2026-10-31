import 'dart:async';

import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/database_helper/database_helper.dart';
import 'package:my_note_app/drive/drive_repository.dart';
import 'package:my_note_app/helper/note_image_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/services/sync_merge.dart';

/// Orchestrates sync between local SQLite and the user's Google Drive.
///
/// Strategy: Offline-First. SQLite is always what the UI reads. Each run lists
/// Drive, merges remote changes, pushes pending local changes, then cleans up.
/// Runs never overlap, so a note can't be uploaded twice at the same time.
class SyncService extends GetxController implements GetxService {
  static const Duration _debounce = Duration(seconds: 2);
  static const Duration _resumeThrottle = Duration(minutes: 1);
  static const Duration _imageGracePeriod = Duration(days: 30);

  SyncService({DriveRepository? repository, bool Function()? isLoggedIn})
    : _repoOverride = repository,
      _isLoggedInOverride = isLoggedIn;

  final DriveRepository? _repoOverride;
  final bool Function()? _isLoggedInOverride;
  final DatabaseHelper _db = DatabaseHelper.instance;

  DriveRepository get _repo => _repoOverride ?? Get.find<DriveRepository>();
  bool get _isLoggedIn =>
      _isLoggedInOverride?.call() ?? Get.find<AuthController>().isLoggedIn();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // 'idle' | 'syncing' | 'done' | 'error' | 'needsDriveAccess' | 'quotaFull'
  String _syncStatus = 'idle';
  String get syncStatus => _syncStatus;

  /// Called once per app session when the user must grant Drive access.
  void Function()? onDriveAccessNeeded;
  bool _driveAccessPromptShown = false;

  Timer? _debounceTimer;
  Future<void>? _currentRun;
  bool _runAgain = false;
  DateTime? _lastRunAt;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Schedules a sync shortly after a local change, batching quick edits.
  void requestSync() {
    if (!_isLoggedIn) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, syncNow);
  }

  /// Syncs on app resume, at most once per [_resumeThrottle].
  void syncOnResume() {
    final last = _lastRunAt;
    if (last != null && DateTime.now().difference(last) < _resumeThrottle) {
      return;
    }
    syncNow();
  }

  /// Runs a sync now. If one is running, a follow-up run is queued instead.
  /// Never throws. The outcome is in [syncStatus].
  Future<void> syncNow() {
    if (!_isLoggedIn) return Future.value();
    final running = _currentRun;
    if (running != null) {
      _runAgain = true;
      return running;
    }
    return _currentRun = _runLoop();
  }

  /// Stops scheduled work and waits for any running sync. Used before local
  /// data is cleared, so a sync can't write into the cleared database.
  Future<void> reset() async {
    _debounceTimer?.cancel();
    _runAgain = false;
    await _currentRun;
    _driveAccessPromptShown = false;
    _setStatus(false, 'idle');
  }

  /// Allows the Drive access prompt to appear again after access was granted.
  void clearDriveAccessPrompt() => _driveAccessPromptShown = false;

  @override
  void onClose() {
    _debounceTimer?.cancel();
    super.onClose();
  }

  // ── Run ─────────────────────────────────────────────────────────────────────

  Future<void> _runLoop() async {
    _setStatus(true, 'syncing');
    try {
      do {
        _runAgain = false;
        _lastRunAt = DateTime.now();
        _debounceTimer?.cancel();
        await _runOnce();
      } while (_runAgain && _syncStatus != 'needsDriveAccess');
    } finally {
      _currentRun = null;
      _repo.endSession();
      _isSyncing = false;
      update();
      _refreshNoteLists();
    }
  }

  Future<void> _runOnce() async {
    try {
      final hadFailures = await _sync();
      _syncStatus = hadFailures ? 'error' : 'done';
    } on DriveAuthRequired {
      _syncStatus = 'needsDriveAccess';
      if (!_driveAccessPromptShown) {
        _driveAccessPromptShown = true;
        onDriveAccessNeeded?.call();
      }
    } on DriveQuotaExceeded {
      _syncStatus = 'quotaFull';
    } catch (e) {
      print('[SyncService] Sync failed: $e');
      _syncStatus = 'error';
    }
  }

  /// One full sync. Returns true if any note or image failed and will retry.
  /// Auth and quota errors stop the run, because every later call would fail.
  Future<bool> _sync() async {
    final remoteFiles = await _repo.listFiles();
    final remoteImages = {
      for (final file in remoteFiles)
        if (NoteImageHelper.isDriveImage(file.name)) file.name: file,
    };

    var hadFailures = await _merge(remoteFiles);
    if (await _pushPending(remoteFiles, remoteImages)) hadFailures = true;
    if (await _downloadMissingImages(remoteImages)) hadFailures = true;
    if (!hadFailures) await _deleteUnusedImages(remoteImages);
    return hadFailures;
  }

  // ── Merge ───────────────────────────────────────────────────────────────────

  Future<bool> _merge(List<RemoteFile> remoteFiles) async {
    final plan = planSync(await _db.getAllNotesForSync(), remoteFiles);
    var hadFailures = false;

    Future<void> guarded(String label, Future<void> Function() step) async {
      try {
        await step();
      } on DriveAuthRequired {
        rethrow;
      } catch (e) {
        hadFailures = true;
        print('[SyncService] $label failed: $e');
      }
    }

    for (final remote in plan.toInsert) {
      await guarded('Insert ${remote.name}', () async {
        await _db.addNote(await _download(remote));
      });
    }
    for (final (local, remote) in plan.toOverwrite) {
      await guarded('Overwrite ${remote.name}', () async {
        await _db.overwriteFromRemote(local.id!, await _download(remote));
      });
    }
    for (final (local, remote) in plan.conflicts) {
      await guarded('Conflict ${remote.name}', () async {
        final resolved = resolveConflict(local, await _download(remote));
        await _db.saveConflict(winner: resolved.winner, copy: resolved.copy);
      });
    }
    for (final (local, remote) in plan.toLink) {
      await _db.linkRemote(local.id!, remote.id, remote.version);
    }
    for (final note in plan.toDeleteLocally) {
      await _db.deleteNote(note);
    }
    await _db.markForReupload(plan.toReupload.map((n) => n.id!).toList());
    for (final duplicate in plan.duplicates) {
      await guarded('Duplicate ${duplicate.name}', () {
        return _repo.deleteFile(duplicate.id);
      });
    }
    return hadFailures;
  }

  Future<Note> _download(RemoteFile remote) async {
    final data = await _repo.downloadJson(remote.id);
    // The file name is authoritative, so a damaged file can't change identity.
    return Note.fromDriveJson(data, fileId: remote.id, version: remote.version)
      ..syncId = syncIdFromFileName(remote.name);
  }

  // ── Push ────────────────────────────────────────────────────────────────────

  Future<bool> _pushPending(
    List<RemoteFile> remoteFiles,
    Map<String, RemoteFile> remoteImages,
  ) async {
    var hadFailures = false;
    final remoteNames = {for (final file in remoteFiles) file.name: file};

    for (final note in await _db.getPendingNotes()) {
      try {
        if (note.syncStatus == 'pendingDelete') {
          final fileId =
              note.cloudId ?? remoteNames[noteFileName(note.syncId!)]?.id;
          if (fileId != null) await _repo.deleteFile(fileId);
          await _db.deleteNote(note);
        } else {
          await _uploadImages(note, remoteImages);
          await _uploadNote(note);
        }
      } on DriveAuthRequired {
        rethrow;
      } on DriveQuotaExceeded {
        rethrow;
      } catch (e) {
        hadFailures = true;
        print('[SyncService] Push failed for note ${note.id}: $e');
      }
    }
    return hadFailures;
  }

  Future<void> _uploadImages(
    Note note,
    Map<String, RemoteFile> remoteImages,
  ) async {
    final localized = await NoteImageHelper.localizeContent(note.content);
    if (localized != null && localized != note.content) {
      note.content = localized;
      await _db.updateContentForSync(note.id!, localized);
    }
    for (final path in NoteImageHelper.referencedImages(note.content)) {
      final name = NoteImageHelper.driveName(path);
      if (remoteImages.containsKey(name)) continue;
      if (!await NoteImageHelper.exists(path)) continue;
      remoteImages[name] = await _repo.createBytes(
        name,
        await NoteImageHelper.read(path),
        'application/octet-stream',
      );
    }
  }

  Future<void> _uploadNote(Note note) async {
    final data = note.toDriveJson();
    RemoteFile uploaded;
    try {
      uploaded =
          note.cloudId == null
              ? await _repo.createJson(noteFileName(note.syncId!), data)
              : await _repo.updateJson(note.cloudId!, data);
    } on DriveFileNotFound {
      uploaded = await _repo.createJson(noteFileName(note.syncId!), data);
    }
    await _db.markUploaded(
      localId: note.id!,
      cloudId: uploaded.id,
      remoteVersion: uploaded.version,
      uploadedUpdatedAt: note.updatedAt,
    );
  }

  // ── Images ──────────────────────────────────────────────────────────────────

  Future<bool> _downloadMissingImages(
    Map<String, RemoteFile> remoteImages,
  ) async {
    var hadFailures = false;
    for (final note in await _db.getAllNotesForSync()) {
      for (final path in NoteImageHelper.referencedImages(note.content)) {
        if (await NoteImageHelper.exists(path)) continue;
        final remote = remoteImages[NoteImageHelper.driveName(path)];
        if (remote == null) continue; // Not uploaded by the other device yet.
        try {
          await NoteImageHelper.write(
            path,
            await _repo.downloadBytes(remote.id),
          );
        } on DriveAuthRequired {
          rethrow;
        } catch (e) {
          hadFailures = true;
          print('[SyncService] Image download failed for $path: $e');
        }
      }
    }
    return hadFailures;
  }

  /// The grace period protects images whose note is still waiting to upload on
  /// another device. Failures are harmless, because the next run retries.
  Future<void> _deleteUnusedImages(Map<String, RemoteFile> remoteImages) async {
    final used = <String>{};
    for (final note in await _db.getAllNotesForSync()) {
      used.addAll(
        NoteImageHelper.referencedImages(
          note.content,
        ).map(NoteImageHelper.driveName),
      );
    }
    final cutoff = DateTime.now().subtract(_imageGracePeriod);
    for (final file in remoteImages.values) {
      final modified = file.modifiedTime;
      if (used.contains(file.name) ||
          modified == null ||
          modified.isAfter(cutoff)) {
        continue;
      }
      try {
        await _repo.deleteFile(file.id);
      } catch (e) {
        print('[SyncService] Image cleanup failed for ${file.name}: $e');
      }
    }
  }

  // ── Utilities ───────────────────────────────────────────────────────────────

  void _setStatus(bool syncing, String status) {
    _isSyncing = syncing;
    _syncStatus = status;
    update();
  }

  void _refreshNoteLists() {
    if (!Get.isRegistered<NoteController>()) return;
    final notes = Get.find<NoteController>();
    notes.getAllNotes();
    notes.getAllDeletedNotes();
  }
}
