import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes_app/controller/auth_controller.dart';
import 'package:notes_app/controller/note_controller.dart';
import 'package:notes_app/model/note_model.dart';
import 'package:uuid/uuid.dart';

class FirebaseController extends GetxController implements GetxService{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<void> uploadAllNotes() async {
    String? userId = Get.find<AuthController>().getUserToken();
    if(userId == null) {
      print('you are not authenticated');
      return;
    }
    if(Get.find<NoteController>().notes.isEmpty) {
      await Get.find<NoteController>().getAllNotes();
    }
    ///Delete the existing notes for the user.

    final docRef = _firestore.collection("users").doc("userId");

// Remove the 'capital' field from the document
//     final updates = <String, dynamic>{
//       "capital": FieldValue.delete(),
//     };
//
//     docRef.update(updates);


    // await _firestore
    //     .collection('users')
    //     .doc(userId)
    //     .collection('notes');

    // docRef.delete().then(
    //       (doc) => print("Document deleted"),
    //   onError: (e) => print("Error updating document $e"),
    // );

    // await _firestore
    //     .collection('users')
    //     .doc(userId)
    //     .delete()
    //     .then((value) => print("User Deleted"))
    //     .catchError((error) => print("Failed to delete user: $error"));

    for(Note note in Get.find<NoteController>().notes) {
      await _addNote(note, userId);
    }
  }

  Future<bool> _addNote(Note note, String? userId) async {
    // Call the user's CollectionReference to add a new user
    //  users
    //     .add({
    //   'full_name': 'fullName', // John Doe
    //   'company': 'company', // Stokes and Sons
    //   'age': 'age' // 42
    // })
    //     .then((value) => print("User Added"))
    //     .catchError((error) => print("Failed to add user: $error"));

    try {

      ///Added the notes for the user
      var uuid = const Uuid().v4();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(uuid)
          .set(note.toJson())
          .then((value) => print("note added"))
          .catchError((error) => print("Failed to add notes: $error"));
      return true;
    } catch (e) {
      print(e);
      return false;
    }
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
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get()
          .then((QuerySnapshot<Map<String, dynamic>> value){

        notes = _processNotes(value);
        print('=====ss==s=s=s=s=s==ss=s=s= > ${jsonEncode(notes)}');

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