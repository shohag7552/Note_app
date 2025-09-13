import 'package:appwrite/appwrite.dart';
import 'package:my_note_app/model/note_model.dart';

class AppWriteService {
  late Client client;
  late Databases databases;
  late Account account;
  late TablesDB tablesDB;

  static const String projectId = "68c477bd0025144ebd1c";
  static const String databaseId = "68c4863d001af960c493"; // create later
  static const String tableId = "notes"; // create later
  static const String endpoint = "https://fra.cloud.appwrite.io/v1"; // or self-hosted URL

  AppWriteService() {
    client = Client()
      ..setEndpoint(endpoint) // Your Appwrite Endpoint
      ..setProject(projectId); // Your project ID

    databases = Databases(client);
    account = Account(client);
    tablesDB = TablesDB(client);
  }

  Future<void> addNote(Note note) async {
    try {
      await tablesDB.createRow(
          databaseId: databaseId,
          tableId: tableId,
          rowId: ID.unique(),
          data: note.toJson(),
      );
    } on AppwriteException catch(e) {
      print(e);
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await tablesDB.updateRow(
        databaseId: databaseId, tableId: tableId,
        rowId: '68c5306acad23e03a01c', data: note.toMapForUpdate(),
      );
    } on AppwriteException catch(e) {
      print(e);
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await tablesDB.deleteRow(databaseId: databaseId, tableId: tableId, rowId: id);
    } on AppwriteException catch(e) {
      print(e);
    }
  }

  Future<void> getNoteList() async {
    try {
      final data = await tablesDB.listRows(
          databaseId: databaseId,
          tableId: tableId,
          queries: [
            Query.orderDesc('dateTimeEdited'),
            // Query.limit(10),
            // Query.offset(1),
            // Query.orderDesc('id'),
            // Query.search('title', 'Hamlet'),
            // Query.equal('title', 'Hamlet')
          ]
      );
      // data.rows.map((doc) {
      //   print('=========doc: ${doc.data}');
      //   // return doc.data;
      // }).toList();
      List<Note> notes = data.rows.map((doc) => Note.fromJson(doc.data)).toList();
      print('=========notes: $notes');
      // print('=========data: ${data.rows.map((a) => print(a.data))}');
    } on AppwriteException catch(e) {
      print(e);
    }

  }

  // Future<List<Note>> getNotes() async {
  //   final res = await databases.listDocuments(
  //     databaseId: databaseId,
  //     collectionId: collectionId,
  //     queries: [
  //       Query.equal('userId', await _getCurrentUserId()),  // If you have a userId field
  //       Query.orderDesc('dateTimeEdited'),
  //     ],
  //   );
  //   return res.documents.map((doc) => Note.fromMap(doc.data)).toList();
  // }

}
