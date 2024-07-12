import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:notes_app/controller/auth_controller.dart';
import 'package:notes_app/controller/note_controller.dart';
import 'package:notes_app/model/note_model.dart';

class FirebaseController extends GetxController implements GetxService{
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;


  Future<void> uploadAllNotes() async {
    String? userId = Get.find<AuthController>().getUserToken();
    if(userId == null) {
      print('you are not authenticated');
      return;
    }
    if(Get.find<NoteController>().notes.isEmpty) {
      await Get.find<NoteController>().getAllNotes();
    }

    for(Note note in Get.find<NoteController>().notes) {
      await _addNote(note, userId);
    }
  }

  Future<bool> _addNote(Note note, String? userId) async {

    try {
      CollectionReference users = _fireStore.collection('users').doc(userId).collection('notes');

      ///delete existing one.
      await _deleteDuplicateNote(users, note.id.toString());

      ///Added the notes for the user
      // var uuid = const Uuid().v4();
      await users
          .doc(note.id.toString())
          .set(note.toJson())
          .then((value) => print("note added"))
          .catchError((error) => print("Failed to add notes: $error"));
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> _deleteDuplicateNote(CollectionReference users, String noteId) {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    return users.get().then((querySnapshot) {
      for (var document in querySnapshot.docs) {
        if(document.id == noteId) {
          batch.delete(document.reference);
          print('note deleted');
        }
      }

      return batch.commit();
    });
  }

  Future<void> getNotesFromCloud() async {
    String? userId = Get.find<AuthController>().getUserToken();
    if(userId == null) {
      print('you are not authenticated');
      return;
    }
    await Get.find<NoteController>().deleteAllNotes();
    List<Note> notes = await _getNotes(userId);
    for(Note note in notes) {
      await Get.find<NoteController>().addNoteToDatabase(title: '', content: '', color: '', cloudNote: note);
    }

    Get.find<NoteController>().getAllNotes();
  }

  Future<List<Note>> _getNotes(String? userId) async {
    List<Note> notes = [];
    try {
      await _fireStore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get()
          .then((QuerySnapshot<Map<String, dynamic>> value){

        notes = _processNotes(value);

      });
      return notes;
    } catch (e) {
      print(e);
      return notes;
    }
  }

  List<Note> _processNotes(QuerySnapshot<Map<String, dynamic>> snapshot) {
    try {
      final List<Note> notesList = snapshot.docs.map((doc) {
        final data = doc.data();
        return Note.fromJson(data);
      }).toList();
      return notesList;
    } catch (e) {
      print(e);
      return [];
    }
  }
}