/// seed_database.dart
///
/// Run with:  dart seed_database.dart
///
/// PURPOSE
/// -------
/// This script connects to your Appwrite project using a server-side API key
/// and idempotently provisions everything the app needs:
///
///   1. Database  → "notes_database"  (id: from AppwriteConfig.databaseId)
///   2. Table     → "notes"           (id: "notes")
///   3. Columns   → all fields used by Note.toCloudMap() + Note.fromAppwrite()
///
/// It is safe to run multiple times – existing resources are skipped, not
/// re-created, so you will never lose data.
///
/// HOW TO GET AN API KEY
/// ---------------------
/// Appwrite Console → Your Project → Overview → API Keys → "Create API key"
/// Grant the following scopes:
///   databases.read, databases.write,
///   collections.read, collections.write,
///   attributes.read, attributes.write,
///   indexes.read, indexes.write
/// Then paste the key below (or export it as APPWRITE_API_KEY).
///
/// IMPORTANT: Never commit a real API key to source control.
/// Use the environment variable instead:
///   export APPWRITE_API_KEY="<your_key>" && dart seed_database.dart

import 'dart:io';
import 'dart:convert';

/// dart seed_database.dart
// ─── Configuration ───────────────────────────────────────────────────────────

const String _endpoint   = 'https://fra.cloud.appwrite.io/v1';
const String _projectId  = '68d0ee2500292ed340a0';
const String _databaseId = '68d3d2560012a0823957';
const String _tableId    = 'notes';
const String _databaseName = 'Notes Database';
const String _tableName    = 'Notes';

/// Put your Appwrite Server API key here, OR export APPWRITE_API_KEY=<key>
const String _hardcodedApiKey = 'standard_e5243d1ab6d8c3e48558af8de0d16d1d3953d9f9084a6290af535ff2e3ca0c053eb55de2ce8a8f22effc2c897a5866778e484dc79abe25f917c30a7f447215b813c895de360a801221bf85a9803b55e5c8f4a5aa7096689b248dbfefbaa66e02facda5b312f637fb068ab7cc930e4f09f2f0395b18e19fe041bc6b2d9007e0d6';

// ─── Entry Point ─────────────────────────────────────────────────────────────

Future<void> main() async {
  final apiKey = Platform.environment['APPWRITE_API_KEY'] ?? _hardcodedApiKey;

  if (apiKey == 'YOUR_APPWRITE_API_KEY_HERE') {
    _error(
      'No API key provided.\n'
      'Set the APPWRITE_API_KEY environment variable or edit seed_database.dart.',
    );
    exit(1);
  }

  final seeder = _AppwriteSeeder(
    endpoint: _endpoint,
    projectId: _projectId,
    apiKey: apiKey,
  );

  _log('🚀  Starting Appwrite database seed...\n');

  // 1. Ensure database exists
  await seeder.ensureDatabase(id: _databaseId, name: _databaseName);

  // 2. Ensure notes table (collection) exists
  await seeder.ensureCollection(
    databaseId: _databaseId,
    collectionId: _tableId,
    collectionName: _tableName,
  );

  // 3. Create all columns (attributes)
  _log('\n📋  Setting up columns…');

  await seeder.ensureStringAttribute(
    databaseId: _databaseId,
    collectionId: _tableId,
    key: 'title',
    size: 500,
    required: true,
    defaultValue: null,
  );

  await seeder.ensureStringAttribute(
    databaseId: _databaseId,
    collectionId: _tableId,
    key: 'content',
    size: 100000, // rich-text JSON can be large
    required: true,
    defaultValue: null,
  );

  await seeder.ensureStringAttribute(
    databaseId: _databaseId,
    collectionId: _tableId,
    key: 'dateTimeEdited',
    size: 50,
    required: true,
    defaultValue: null,
  );

  await seeder.ensureStringAttribute(
    databaseId: _databaseId,
    collectionId: _tableId,
    key: 'dateTimeCreated',
    size: 50,
    required: true,
    defaultValue: null,
  );

  await seeder.ensureIntegerAttribute(
    databaseId: _databaseId,
    collectionId: _tableId,
    key: 'isFavorite',
    required: false,
    defaultValue: 0,
    min: 0,
    max: 1,
  );

  await seeder.ensureStringAttribute(
    databaseId: _databaseId,
    collectionId: _tableId,
    key: 'color',
    size: 20,
    required: false,
    defaultValue: '#FFA0A4A8',
  );

  await seeder.ensureStringAttribute(
    databaseId: _databaseId,
    collectionId: _tableId,
    key: 'authorEmail',
    size: 255,
    required: false,
    defaultValue: null,
  );

  await seeder.ensureIntegerAttribute(
    databaseId: _databaseId,
    collectionId: _tableId,
    key: 'localId',
    required: false,
    defaultValue: null,
  );

  // 4. Wait for all attributes to become available, then create indexes
  _log('\n⏳  Waiting for attributes to be ready…');
  await _waitForAttributes(seeder, _databaseId, _tableId, 8);

  // 5. Create useful indexes
  _log('\n🔍  Setting up indexes…');

  await seeder.ensureIndex(
    databaseId: _databaseId,
    collectionId: _tableId,
    indexKey: 'idx_author_email',
    type: 'key',
    attributes: ['authorEmail'],
    orders: ['ASC'],
  );

  await seeder.ensureIndex(
    databaseId: _databaseId,
    collectionId: _tableId,
    indexKey: 'idx_date_edited',
    type: 'key',
    attributes: ['dateTimeEdited'],
    orders: ['DESC'],
  );

  await seeder.ensureIndex(
    databaseId: _databaseId,
    collectionId: _tableId,
    indexKey: 'idx_is_favorite',
    type: 'key',
    attributes: ['isFavorite'],
    orders: ['DESC'],
  );

  _log('\n✅  Seed complete! Your Appwrite "notes" table is ready.\n');
  _log('    Database ID : $_databaseId');
  _log('    Table ID    : $_tableId');
}

// ─── Attribute-Readiness Helper ───────────────────────────────────────────────

/// Polls Appwrite until all [expectedCount] attributes are in "available" state.
Future<void> _waitForAttributes(
  _AppwriteSeeder seeder,
  String databaseId,
  String collectionId,
  int expectedCount,
) async {
  const maxWait = Duration(seconds: 60);
  const pollInterval = Duration(seconds: 3);
  final deadline = DateTime.now().add(maxWait);

  while (DateTime.now().isBefore(deadline)) {
    final attrs = await seeder.listAttributes(
      databaseId: databaseId,
      collectionId: collectionId,
    );
    final available = attrs.where((a) => a['status'] == 'available').length;
    _log('   $available / $expectedCount attributes ready…');
    if (available >= expectedCount) return;
    await Future.delayed(pollInterval);
  }
  _log('⚠️  Timed out waiting for attributes. Proceeding anyway.');
}

// ─── Seeder Class ─────────────────────────────────────────────────────────────

class _AppwriteSeeder {
  final HttpClient _client = HttpClient();
  final String endpoint;
  final String projectId;
  final String apiKey;

  _AppwriteSeeder({
    required this.endpoint,
    required this.projectId,
    required this.apiKey,
  });

  // ── Database ──────────────────────────────────────────────────────────────

  Future<void> ensureDatabase({
    required String id,
    required String name,
  }) async {
    _log('📦  Checking database "$name" ($id)…');
    final exists = await _resourceExists('$endpoint/databases/$id');
    if (exists) {
      _log('    ✔ Database already exists – skipping.');
      return;
    }

    _log('    Creating database…');
    await _post('$endpoint/databases', {
      'databaseId': id,
      'name': name,
    });
    _log('    ✔ Database created.');
  }

  // ── Collection / Table ────────────────────────────────────────────────────

  Future<void> ensureCollection({
    required String databaseId,
    required String collectionId,
    required String collectionName,
  }) async {
    final url = '$endpoint/databases/$databaseId/collections/$collectionId';
    _log('\n📁  Checking collection "$collectionName" ($collectionId)…');

    final exists = await _resourceExists(url);
    if (exists) {
      _log('    ✔ Collection already exists – skipping.');
      return;
    }

    _log('    Creating collection…');
    await _post('$endpoint/databases/$databaseId/collections', {
      'collectionId': collectionId,
      'name': collectionName,
      'documentSecurity': true, // per-document permissions (used by the app)
    });
    _log('    ✔ Collection created.');
  }

  // ── Attributes ────────────────────────────────────────────────────────────

  Future<void> ensureStringAttribute({
    required String databaseId,
    required String collectionId,
    required String key,
    required int size,
    required bool required,
    String? defaultValue,
    bool array = false,
  }) async {
    final base =
        '$endpoint/databases/$databaseId/collections/$collectionId/attributes';
    final existing = await _listAttributeKeys(databaseId, collectionId);
    if (existing.contains(key)) {
      _log('    ✔ Column "$key" already exists – skipping.');
      return;
    }

    _log('    ➕ Creating STRING column "$key" (size: $size)…');
    final body = <String, dynamic>{
      'key': key,
      'size': size,
      'required': required,
      'array': array,
    };
    if (!required && defaultValue != null) body['default'] = defaultValue;

    await _post('$base/string', body);
    _log('    ✔ Column "$key" created.');
  }

  Future<void> ensureIntegerAttribute({
    required String databaseId,
    required String collectionId,
    required String key,
    required bool required,
    int? defaultValue,
    int? min,
    int? max,
    bool array = false,
  }) async {
    final base =
        '$endpoint/databases/$databaseId/collections/$collectionId/attributes';
    final existing = await _listAttributeKeys(databaseId, collectionId);
    if (existing.contains(key)) {
      _log('    ✔ Column "$key" already exists – skipping.');
      return;
    }

    _log('    ➕ Creating INTEGER column "$key"…');
    final body = <String, dynamic>{
      'key': key,
      'required': required,
      'array': array,
    };
    if (!required && defaultValue != null) body['default'] = defaultValue;
    if (min != null) body['min'] = min;
    if (max != null) body['max'] = max;

    await _post('$base/integer', body);
    _log('    ✔ Column "$key" created.');
  }

  // ── Indexes ───────────────────────────────────────────────────────────────

  Future<void> ensureIndex({
    required String databaseId,
    required String collectionId,
    required String indexKey,
    required String type,
    required List<String> attributes,
    required List<String> orders,
  }) async {
    final base =
        '$endpoint/databases/$databaseId/collections/$collectionId/indexes';
    final existingIndexes = await _listIndexKeys(databaseId, collectionId);
    if (existingIndexes.contains(indexKey)) {
      _log('    ✔ Index "$indexKey" already exists – skipping.');
      return;
    }

    _log('    ➕ Creating index "$indexKey"…');
    await _post(base, {
      'key': indexKey,
      'type': type,
      'attributes': attributes,
      'orders': orders,
    });
    _log('    ✔ Index "$indexKey" created.');
  }

  // ── Listing Helpers ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> listAttributes(
      {required String databaseId, required String collectionId}) async {
    final url =
        '$endpoint/databases/$databaseId/collections/$collectionId/attributes';
    final response = await _get(url);
    final data = jsonDecode(response) as Map<String, dynamic>;
    final attrs = data['attributes'] as List<dynamic>? ?? [];
    return attrs.cast<Map<String, dynamic>>();
  }

  Future<Set<String>> _listAttributeKeys(
      String databaseId, String collectionId) async {
    final attrs = await listAttributes(
        databaseId: databaseId, collectionId: collectionId);
    return attrs.map((a) => a['key'] as String).toSet();
  }

  Future<Set<String>> _listIndexKeys(
      String databaseId, String collectionId) async {
    final url =
        '$endpoint/databases/$databaseId/collections/$collectionId/indexes';
    final response = await _get(url);
    final data = jsonDecode(response) as Map<String, dynamic>;
    final indexes = data['indexes'] as List<dynamic>? ?? [];
    return indexes.map((i) => i['key'] as String).toSet();
  }

  // ── HTTP Helpers ──────────────────────────────────────────────────────────

  Future<bool> _resourceExists(String url) async {
    try {
      await _get(url);
      return true;
    } on HttpException catch (e) {
      if (e.message.contains('404')) return false;
      rethrow;
    }
  }

  Future<String> _get(String url) async {
    final uri = Uri.parse(url);
    final request = await _client.getUrl(uri);
    _setHeaders(request);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 404) {
      throw HttpException('404: Not found', uri: uri);
    }
    if (response.statusCode >= 400) {
      throw HttpException(
          'HTTP ${response.statusCode}: $body', uri: uri);
    }
    return body;
  }

  Future<String> _post(String url, Map<String, dynamic> payload) async {
    final uri = Uri.parse(url);
    final request = await _client.postUrl(uri);
    _setHeaders(request);
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(payload));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 409) {
      // 409 Conflict → resource already exists, that is fine
      return body;
    }
    if (response.statusCode >= 400) {
      throw HttpException(
          'HTTP ${response.statusCode}: $body', uri: uri);
    }
    return body;
  }

  void _setHeaders(HttpClientRequest request) {
    request.headers.set('X-Appwrite-Project', projectId);
    request.headers.set('X-Appwrite-Key', apiKey);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('X-Appwrite-Response-Format', '1.7.0');
  }
}

// ─── Logging ─────────────────────────────────────────────────────────────────

void _log(String msg) => stdout.writeln(msg);
void _error(String msg) => stderr.writeln('❌  $msg');
