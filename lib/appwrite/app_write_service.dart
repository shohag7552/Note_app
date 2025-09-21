// lib/services/appwrite_service.dart
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_note_app/appwrite/app_write_config.dart';

class AppwriteService {
  late final Client client;
  late final Databases databases;
  late final Account account;
  late final TablesDB tablesDB;
  static final AppwriteService _instance = AppwriteService._internal();

  factory AppwriteService() => _instance;

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);

    databases = Databases(client);
    account = Account(client);
    tablesDB = TablesDB(client);
  }

  // Database operations
  Future<void> createDocument({
    required String collectionId,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    print('======mmmm===> $data // $collectionId // $documentId // ${AppwriteConfig.databaseId}');
    // return await databases.createDocument(
    //   databaseId: AppwriteConfig.databaseId,
    //   collectionId: collectionId,
    //   documentId: documentId ?? ID.unique(),
    //   data: data,
    // );
    try {
      tablesDB.createRow(
        databaseId: AppwriteConfig.databaseId,
        tableId: collectionId,
        rowId: documentId ?? ID.unique(),
        data: data,
      );
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<Document> getDocument({
    required String collectionId,
    required String documentId,
  }) async {
    return await databases.getDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }

  Future<DocumentList> listDocuments({
    required String collectionId,
    List<String>? queries,
  }) async {
    return await databases.listDocuments(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      queries: queries ?? [],
    );
  }

  Future<Document> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    return await databases.updateDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: data,
    );
  }

  Future<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    return await databases.deleteDocument(
      databaseId: AppwriteConfig.databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }
}