import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// The user must grant Drive access before sync can continue.
class DriveAuthRequired implements Exception {}

/// The user's Google storage is full.
class DriveQuotaExceeded implements Exception {}

/// The Drive file no longer exists.
class DriveFileNotFound implements Exception {}

/// Metadata of one file in the app's hidden Drive folder.
class RemoteFile {
  final String id;
  final String name;
  final String version;
  final DateTime? modifiedTime;

  const RemoteFile({
    required this.id,
    required this.name,
    required this.version,
    this.modifiedTime,
  });
}

/// Returns an authenticated client, or throws [DriveAuthRequired].
typedef DriveClientProvider = Future<http.Client> Function({bool forceRefresh});

/// Reads and writes files in the user's hidden `appDataFolder`.
class DriveRepository {
  static const String _space = 'appDataFolder';
  static const int _maxAttempts = 3;
  static const String _fileFields = 'id,name,version,modifiedTime';

  final DriveClientProvider _clientProvider;
  http.Client? _client;

  DriveRepository({required DriveClientProvider clientProvider})
    : _clientProvider = clientProvider;

  Future<List<RemoteFile>> listFiles() async {
    final files = <RemoteFile>[];
    String? pageToken;
    do {
      final token = pageToken;
      final page = await _call(
        (api) => api.files.list(
          spaces: _space,
          pageSize: 1000,
          pageToken: token,
          $fields: 'nextPageToken,files($_fileFields)',
        ),
      );
      files.addAll((page.files ?? const <drive.File>[]).map(_toRemoteFile));
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return files;
  }

  Future<Map<String, dynamic>> downloadJson(String fileId) async {
    final bytes = await downloadBytes(fileId);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  Future<List<int>> downloadBytes(String fileId) {
    return _call((api) async {
      final media =
          await api.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return bytes;
    });
  }

  Future<RemoteFile> createJson(String name, Map<String, dynamic> data) =>
      createBytes(name, utf8.encode(jsonEncode(data)), 'application/json');

  Future<RemoteFile> updateJson(String fileId, Map<String, dynamic> data) {
    final bytes = utf8.encode(jsonEncode(data));
    return _call((api) async {
      final file = await api.files.update(
        drive.File(),
        fileId,
        uploadMedia: _media(bytes, 'application/json'),
        $fields: _fileFields,
      );
      return _toRemoteFile(file);
    });
  }

  Future<RemoteFile> createBytes(
    String name,
    List<int> bytes,
    String contentType,
  ) {
    return _call((api) async {
      final file = await api.files.create(
        drive.File(name: name, parents: [_space]),
        uploadMedia: _media(bytes, contentType),
        $fields: _fileFields,
      );
      return _toRemoteFile(file);
    });
  }

  /// Deleting a file that's already gone counts as success.
  Future<void> deleteFile(String fileId) async {
    try {
      await _call((api) => api.files.delete(fileId));
    } on DriveFileNotFound {
      return;
    }
  }

  Future<void> deleteAllAppData() async {
    for (final file in await listFiles()) {
      await deleteFile(file.id);
    }
  }

  /// Releases the client. The next call fetches a fresh access token.
  void endSession() {
    _client?.close();
    _client = null;
  }

  /// Runs [request], retrying transient failures and refreshing the access
  /// token once if Google rejects it.
  Future<T> _call<T>(Future<T> Function(drive.DriveApi api) request) async {
    var refreshedToken = false;
    for (var attempt = 1; ; attempt++) {
      try {
        _client ??= await _clientProvider();
        return await request(drive.DriveApi(_client!));
      } on drive.DetailedApiRequestError catch (e) {
        if (e.status == 401 && !refreshedToken) {
          refreshedToken = true;
          endSession();
          _client = await _clientProvider(forceRefresh: true);
          attempt--;
          continue;
        }
        if (e.status == 401) throw DriveAuthRequired();
        if (e.status == 404) throw DriveFileNotFound();
        if (e.status == 403) {
          final reasons = e.errors.map((err) => err.reason).toSet();
          if (reasons.contains('storageQuotaExceeded')) {
            throw DriveQuotaExceeded();
          }
          if (reasons.contains('insufficientPermissions') ||
              reasons.contains('insufficientScopes')) {
            throw DriveAuthRequired();
          }
        }
        final retryable =
            e.status == 429 ||
            (e.status != null && e.status! >= 500) ||
            (e.status == 403 && _isRateLimit(e));
        if (!retryable || attempt >= _maxAttempts) rethrow;
      } on SocketException {
        if (attempt >= _maxAttempts) rethrow;
      } on http.ClientException {
        if (attempt >= _maxAttempts) rethrow;
      } on TimeoutException {
        if (attempt >= _maxAttempts) rethrow;
      }
      await Future<void>.delayed(Duration(seconds: 1 << attempt));
    }
  }

  static bool _isRateLimit(drive.DetailedApiRequestError e) => e.errors.any(
    (err) =>
        err.reason == 'rateLimitExceeded' ||
        err.reason == 'userRateLimitExceeded',
  );

  static drive.Media _media(List<int> bytes, String contentType) => drive.Media(
    Stream<List<int>>.value(bytes),
    bytes.length,
    contentType: contentType,
  );

  static RemoteFile _toRemoteFile(drive.File file) => RemoteFile(
    id: file.id!,
    name: file.name ?? '',
    version: file.version ?? '',
    modifiedTime: file.modifiedTime,
  );
}
