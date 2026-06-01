import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'package:my_note_app/appwrite/app_write_config.dart';
import 'package:my_note_app/appwrite/app_write_service.dart';
import 'package:my_note_app/appwrite/repository/app_write_repository.dart';
import 'package:my_note_app/database_helper/database_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Orchestrates bidirectional sync between local SQLite and Appwrite.
///
/// Strategy: Offline-First with Last-Write-Wins (LWW) conflict resolution.
///   1. Push pending local changes → cloud.
///   2. Pull all cloud notes → upsert locally (paginated).
///
/// Also manages the Appwrite Realtime subscription so changes from
/// other devices are pulled automatically while the app is open.
class SyncService extends GetxController implements GetxService {
  final AppWriteRepository _repo = AppWriteRepository();
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String _syncStatus = 'idle'; // 'idle' | 'syncing' | 'done' | 'error'
  String get syncStatus => _syncStatus;

  RealtimeSubscription? _realtimeSubscription;
  String? _realtimeEmail;

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Full bidirectional sync. Call after login or manual "Sync Now".
  Future<void> syncOnLogin(String authorEmail) async {
    if (_isSyncing) return;
    _setSyncing(true, 'syncing');
    try {
      await _pushPendingLocalChanges(authorEmail);
      await _pullCloudNotes(authorEmail);
      _setSyncing(false, 'done');
    } catch (e) {
      _setSyncing(false, 'error');
      rethrow;
    }
  }

  /// Push-only sync. Called on app resume (auto-retry) — lightweight.
  Future<void> pushAllPending(String authorEmail) async {
    if (_isSyncing) return;
    try {
      await _pushPendingLocalChanges(authorEmail);
    } catch (e) {
      print('[SyncService] pushAllPending error: $e');
    }
  }

  /// Push a single note immediately after a UI action.
  Future<void> pushNote(Note note, String authorEmail) async {
    note.authorEmail = authorEmail;
    if (note.syncStatus == 'pendingDelete') {
      await _deleteFromCloud(note);
    } else if (note.cloudId == null) {
      await _pushNewNote(note);
    } else {
      await _updateCloudNote(note);
    }
  }

  // ── Real-Time Subscription ─────────────────────────────────────────────────

  /// Subscribe to Appwrite Realtime for the notes table.
  /// Any change from another device triggers a pull sync automatically.
  void startRealtimeSync(String email) {
    _realtimeEmail = email;
    _realtimeSubscription?.close();

    _realtimeSubscription = AppwriteService().realtime.subscribe([
      // Channel format for Appwrite v19 TablesDB realtime events.
      'databases.${AppwriteConfig.databaseId}.collections.${AppwriteConfig.noteTable}.documents',
    ]);

    _realtimeSubscription!.stream.listen(
      (event) async {
        // A change arrived from another device — pull the latest notes.
        if (_realtimeEmail != null && !_isSyncing) {
          try {
            await _pullCloudNotes(_realtimeEmail!);
            update(); // Notify UI listeners (e.g. NoteController)
          } catch (e) {
            print('[SyncService] Realtime pull error: $e');
          }
        }
      },
      onError: (e) => print('[SyncService] Realtime error: $e'),
    );
  }

  /// Stop the Realtime subscription (on logout or app background).
  void stopRealtimeSync() {
    _realtimeSubscription?.close();
    _realtimeSubscription = null;
    _realtimeEmail = null;
  }

  // ── Private: Push ──────────────────────────────────────────────────────────

  Future<void> _pushPendingLocalChanges(String authorEmail) async {
    final pending = await _db.getPendingNotes();
    for (final note in pending) {
      try {
        note.authorEmail = authorEmail;
        if (note.syncStatus == 'pendingDelete' && note.cloudId != null) {
          await _deleteFromCloud(note);
        } else if (note.cloudId == null) {
          await _pushNewNote(note);
        } else {
          await _updateCloudNote(note);
        }
      } catch (e) {
        print('[SyncService] Push failed for note ${note.id}: $e');
      }
    }
  }

  Future<void> _pushNewNote(Note note) async {
    // Include the Appwrite userId so server-enforced permissions are set.
    final userId = _getAppwriteUserId();
    final cloudId = await _repo.createNote(note: note, userId: userId);
    if (note.id != null) {
      await _db.updateCloudSync(
        localId: note.id!,
        cloudId: cloudId,
        syncStatus: 'synced',
      );
    }
  }

  Future<void> _updateCloudNote(Note note) async {
    await _repo.updateNote(cloudId: note.cloudId!, note: note);
    if (note.id != null) {
      await _db.updateCloudSync(
        localId: note.id!,
        cloudId: note.cloudId!,
        syncStatus: 'synced',
      );
    }
  }

  Future<void> _deleteFromCloud(Note note) async {
    if (note.cloudId != null) {
      await _repo.deleteNote(cloudId: note.cloudId!);
    }
    if (note.id != null) {
      await _db.deleteNote(note);
    }
  }

  // ── Private: Pull (Paginated) ──────────────────────────────────────────────

  Future<void> _pullCloudNotes(String authorEmail) async {
    // Paginated fetch — never misses notes beyond the 100-row limit.
    final cloudNotes = await _fetchAllCloudNotesPaginated(authorEmail);

    for (final cloudNote in cloudNotes) {
      try {
        final localNote = await _db.getNoteByCloudId(cloudNote.cloudId!);

        if (localNote == null) {
          // New note from another device — insert locally.
          cloudNote.syncStatus = 'synced';
          await _db.addNote(cloudNote);
        } else {
          // Conflict resolution: Last-Write-Wins on dateTimeEdited.
          final cloudTime = _parseDate(cloudNote.dateTimeEdited);
          final localTime = _parseDate(localNote.dateTimeEdited);

          if (cloudTime != null &&
              localTime != null &&
              cloudTime.isAfter(localTime) &&
              localNote.syncStatus != 'pending') {
            // Cloud version is newer — overwrite local.
            cloudNote.id = localNote.id;
            cloudNote.syncStatus = 'synced';
            await _db.updateNote(cloudNote);
          } else if (localNote.syncStatus != 'pending') {
            // Even if timestamps match, sync isDeleted state from cloud
            // so trash operations from other devices are reflected locally.
            if ((cloudNote.isDeleted ?? 0) != (localNote.isDeleted ?? 0)) {
              localNote.isDeleted = cloudNote.isDeleted;
              localNote.deletedAt = cloudNote.deletedAt;
              localNote.syncStatus = 'synced';
              await _db.updateNote(localNote);
            }
          }
          // If local is newer or has pending changes, leave it — it will push.
        }
      } catch (e) {
        print('[SyncService] Pull failed for note ${cloudNote.cloudId}: $e');
      }
    }
  }


  /// Fetches ALL cloud notes using offset pagination.
  /// Loops until a page with fewer than 100 results is returned.
  Future<List<Note>> _fetchAllCloudNotesPaginated(String authorEmail) async {
    final List<Note> all = [];
    int offset = 0;
    const pageSize = 100;

    while (true) {
      final page = await _repo.getNotes(
        authorEmail: authorEmail,
        limit: pageSize,
        offset: offset,
      );
      all.addAll(page);
      if (page.length < pageSize) break; // Last page — stop.
      offset += pageSize;
    }
    return all;
  }

  // ── Utilities ──────────────────────────────────────────────────────────────

  void _setSyncing(bool syncing, String status) {
    _isSyncing = syncing;
    _syncStatus = status;
    update();
  }

  /// Reads the Appwrite user.$id from SharedPreferences for permissions.
  String? _getAppwriteUserId() {
    try {
      return Get.find<SharedPreferences>().getString(AppConstants.authId);
    } catch (_) {
      return null;
    }
  }

  /// Parses ISO-8601 or legacy 'dd-MM-yyyy hh:mm a' date strings.
  DateTime? _parseDate(String? raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      try {
        final parts = raw.split(' ');
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        final isPM = parts.length > 2 && parts[2].toLowerCase() == 'pm';
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        return DateTime(year, month, day, hour, minute);
      } catch (_) {
        return null;
      }
    }
  }
}
