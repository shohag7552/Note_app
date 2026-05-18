import 'package:appwrite/appwrite.dart';
import 'package:my_note_app/appwrite/app_write_config.dart';
import 'package:my_note_app/appwrite/app_write_service.dart';
import 'package:my_note_app/model/note_model.dart';

class AppWriteRepository {
  final AppwriteService _service = AppwriteService();

  // ── Fetch (paginated) ──────────────────────────────────────────────────────

  /// Returns one page of notes for [authorEmail].
  /// Caller is responsible for paginating via [offset].
  Future<List<Note>> getNotes({
    required String authorEmail,
    int limit = 100,
    int offset = 0,
  }) async {
    final response = await _service.listRows(
      collectionId: AppwriteConfig.noteTable,
      queries: [
        Query.equal('authorEmail', authorEmail),
        Query.orderDesc('dateTimeEdited'),
        Query.limit(limit),
        Query.offset(offset),
      ],
    );
    return response.rows
        .map((row) => Note.fromAppwrite(row.data, row.$id))
        .toList();
  }

  // ── Create ─────────────────────────────────────────────────────────────────

  /// Creates a note in Appwrite. Pass [userId] to set server-enforced
  /// read/write permissions so only that user can access this note.
  Future<String> createNote({required Note note, String? userId}) async {
    final permissions = userId != null
        ? [
            Permission.read(Role.user(userId)),
            Permission.write(Role.user(userId)),
            Permission.delete(Role.user(userId)),
          ]
        : null;

    final row = await _service.createRow(
      collectionId: AppwriteConfig.noteTable,
      data: note.toCloudMap(),
      permissions: permissions,
    );
    return row.$id;
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<void> updateNote({required String cloudId, required Note note}) async {
    await _service.updateRow(
      collectionId: AppwriteConfig.noteTable,
      rowId: cloudId,
      data: note.toCloudMap(),
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteNote({required String cloudId}) async {
    await _service.deleteRow(
      collectionId: AppwriteConfig.noteTable,
      rowId: cloudId,
    );
  }
}