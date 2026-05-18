import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides UI-facing wrappers for manual sync operations (e.g. drawer buttons).
/// Actual sync logic lives in [SyncService].
class BackgroundController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  BackgroundController({required this.sharedPreferences});

  /// Pull notes from cloud → local, then refresh the notes list.
  Future<void> getAllNotes() async {
    final email = Get.find<AuthController>().getUserToken();
    if (email == null) return;

    try {
      final syncService = Get.find<SyncService>();
      // Re-use the pull step from SyncService.
      await syncService.syncOnLogin(email);
      await Get.find<NoteController>().getAllNotes();
    } catch (e) {
      print('[BackgroundController] Pull notes error: $e');
    }
  }

  /// Push all local notes to cloud (useful for first-time backup).
  Future<void> uploadAllNotes() async {
    final email = Get.find<AuthController>().getUserToken();
    if (email == null) return;

    try {
      // Mark all notes as pending so SyncService will push them.
      final notes = Get.find<NoteController>().notes;
      final syncService = Get.find<SyncService>();
      for (final note in notes) {
        note.syncStatus = 'pending';
        await syncService.pushNote(note, email);
      }
      await Get.find<NoteController>().getAllNotes();
    } catch (e) {
      print('[BackgroundController] Upload notes error: $e');
    }
  }
}