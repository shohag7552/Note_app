import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:my_note_app/appwrite/app_write_config.dart';

class AppwriteService {
  late final Client client;
  late final TablesDB tablesDB;
  late final Account account;
  late final Realtime realtime;

  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;

  AppwriteService._internal() {
    client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    tablesDB = TablesDB(client);
    account = Account(client);
    realtime = Realtime(client);
  }

  // ── Auth helpers ────────────────────────────────────────────────────────────

  /// Returns true if there is a valid active Appwrite session.
  Future<bool> hasActiveSession() async {
    try {
      await account.get();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the current Appwrite session (logout).
  Future<void> deleteCurrentSession() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (_) {}
  }

  // ── Database CRUD (TablesDB — Appwrite SDK v19+) ────────────────────────────

  Future<Row> createRow({
    required String collectionId,
    required Map<String, dynamic> data,
    String? rowId,
    List<String>? permissions,
  }) async {
    return await tablesDB.createRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: rowId ?? ID.unique(),
      data: data,
      permissions: permissions,
    );
  }

  Future<Row> getRow({
    required String collectionId,
    required String rowId,
  }) async {
    return await tablesDB.getRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: rowId,
    );
  }

  Future<RowList> listRows({
    required String collectionId,
    List<String>? queries,
  }) async {
    return await tablesDB.listRows(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      queries: queries ?? [],
    );
  }

  Future<Row> updateRow({
    required String collectionId,
    required String rowId,
    required Map<String, dynamic> data,
  }) async {
    return await tablesDB.updateRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: rowId,
      data: data,
    );
  }

  Future<void> deleteRow({
    required String collectionId,
    required String rowId,
  }) async {
    await tablesDB.deleteRow(
      databaseId: AppwriteConfig.databaseId,
      tableId: collectionId,
      rowId: rowId,
    );
  }
}