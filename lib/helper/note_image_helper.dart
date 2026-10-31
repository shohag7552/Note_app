import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Stores note images in the app documents directory and reads image
/// references out of Quill content.
///
/// Notes keep the relative form `note_images/<uuid>.<ext>?w=300`, because
/// absolute app paths differ between devices and installs.
class NoteImageHelper {
  static const String _folder = 'note_images';
  static const String _drivePrefix = 'img_';
  static late String _documentsPath;

  static Future<void> init() async {
    _documentsPath = (await getApplicationDocumentsDirectory()).path;
  }

  /// Absolute file path for an image path stored in a note.
  static String resolve(String path) =>
      p.isAbsolute(path) ? path : p.join(_documentsPath, path);

  /// Copies a picked image into app storage and returns its relative path.
  static Future<String> importPicked(String sourcePath) async {
    final relative = _newRelativePath(sourcePath);
    final target = File(resolve(relative));
    await target.parent.create(recursive: true);
    await File(sourcePath).copy(target.path);
    return relative;
  }

  /// Moves images referenced by absolute path (notes written by older app
  /// versions) into app storage and rewrites the references. A file that no
  /// longer exists is left unchanged so the note's text can still sync.
  static Future<String?> localizeContent(String? content) async {
    final ops = _decodeOps(content);
    if (ops == null) return content;
    var changed = false;
    for (final op in ops) {
      final ref = _imageRef(op);
      if (ref == null) continue;
      final path = ref.split('?').first;
      if (!p.isAbsolute(path) || !await File(path).exists()) continue;
      final relative = await importPicked(path);
      final query = ref.contains('?') ? '?${ref.split('?').last}' : '';
      ((op as Map)['insert'] as Map)['image'] = '$relative$query';
      changed = true;
    }
    return changed ? jsonEncode(ops) : content;
  }

  /// Relative image paths used by [content], without their size query.
  static Set<String> referencedImages(String? content) {
    final images = <String>{};
    for (final op in _decodeOps(content) ?? const []) {
      final path = _imageRef(op)?.split('?').first;
      if (path != null && p.dirname(path) == _folder) images.add(path);
    }
    return images;
  }

  static String driveName(String relativePath) =>
      '$_drivePrefix${p.basename(relativePath)}';

  static bool isDriveImage(String fileName) => fileName.startsWith(_drivePrefix);

  static Future<bool> exists(String relativePath) =>
      File(resolve(relativePath)).exists();

  static Future<Uint8List> read(String relativePath) =>
      File(resolve(relativePath)).readAsBytes();

  /// Writes through a temp file so an interrupted download never leaves a
  /// partial image that would look complete on the next sync.
  static Future<void> write(String relativePath, List<int> bytes) async {
    final target = File(resolve(relativePath));
    await target.parent.create(recursive: true);
    final temp = File('${target.path}.part');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(target.path);
  }

  static Future<void> deleteAll() async {
    final dir = Directory(p.join(_documentsPath, _folder));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static String _newRelativePath(String sourcePath) =>
      p.join(_folder, '${const Uuid().v4()}${p.extension(sourcePath)}');

  static List<dynamic>? _decodeOps(String? content) {
    if (content == null || content.isEmpty) return null;
    try {
      final decoded = jsonDecode(content);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null; // Plain-text content from older notes has no images.
    }
  }

  static String? _imageRef(dynamic op) {
    if (op is! Map) return null;
    final insert = op['insert'];
    if (insert is! Map) return null;
    final image = insert['image'];
    return image is String ? image : null;
  }
}
