import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Note {
  int? id;            // local SQLite primary key
  String? syncId;     // stable UUID shared by every device holding this note
  String? cloudId;    // Google Drive file id (null when not uploaded yet)
  String? remoteVersion; // Drive file version this row was last synced with
  int? updatedAt;     // UTC milliseconds of the last change, used for conflicts
  String? syncStatus; // 'synced' | 'pending' | 'pendingDelete'
  String? syncBase;   // [syncState] at the last sync, shows which side changed
  String? title;
  String? dateTimeEdited;
  String? dateTimeCreated;
  int? isFavorite;
  String? color;
  String? content;
  int? isDeleted;     // 0 = active, 1 = in recycle bin
  String? deletedAt;  // ISO-8601 timestamp when moved to trash

  Note({
    this.id,
    this.syncId,
    this.cloudId,
    this.remoteVersion,
    this.updatedAt,
    this.syncStatus = 'synced',
    this.syncBase,
    this.title,
    this.content,
    this.dateTimeEdited,
    this.dateTimeCreated,
    this.isFavorite,
    this.color = '#FFA0A4A8',
    this.isDeleted = 0,
    this.deletedAt,
  });

  /// Deserialise from local SQLite row.
  Note.fromJson(Map<String, dynamic> json) {
    id = json['note_id'];
    syncId = json['syncId'] as String?;
    cloudId = json['cloudId'] as String?;
    remoteVersion = json['remoteVersion'] as String?;
    updatedAt = json['updatedAt'] as int?;
    syncStatus = (json['syncStatus'] as String?) ?? 'synced';
    syncBase = json['syncBase'] as String?;
    title = json['title'];
    content = json['content'];
    dateTimeEdited = json['dateTimeEdited'];
    dateTimeCreated = json['dateTimeCreated'];
    isFavorite = json['isFavorite'];
    color = json['color'];
    isDeleted = (json['isDeleted'] as int?) ?? 0;
    deletedAt = json['deletedAt'] as String?;
  }

  /// Deserialise from a note file stored in Google Drive.
  factory Note.fromDriveJson(
    Map<String, dynamic> data, {
    required String fileId,
    required String version,
  }) {
    final note = Note(
      syncId: data['syncId'] as String?,
      cloudId: fileId,
      remoteVersion: version,
      updatedAt: data['updatedAt'] as int?,
      syncStatus: 'synced',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      dateTimeEdited: data['dateTimeEdited'] as String? ?? '',
      dateTimeCreated: data['dateTimeCreated'] as String? ?? '',
      isFavorite: data['isFavorite'] as int? ?? 0,
      color: data['color'] as String? ?? '#FFA0A4A8',
      isDeleted: data['isDeleted'] as int? ?? 0,
      deletedAt: data['deletedAt'] as String?,
    );
    return note..syncBase = note.syncState;
  }

  /// The fields users change, compared against [syncBase] when both sides
  /// changed. The text is hashed to keep the stored value small.
  String get syncState => jsonEncode(syncStateFields);

  Map<String, dynamic> get syncStateFields => {
    'content': sha256.convert(utf8.encode(content ?? '')).toString(),
    'color': color,
    'isFavorite': isFavorite ?? 0,
    'isDeleted': isDeleted ?? 0,
  };

  /// Serialise for local SQLite (includes all local fields).
  Map<String, dynamic> toJson() {
    return {
      'note_id': id,
      'syncId': syncId,
      'cloudId': cloudId,
      'remoteVersion': remoteVersion,
      'updatedAt': updatedAt,
      'syncStatus': syncStatus ?? 'synced',
      'syncBase': syncBase,
      'title': title,
      'content': content,
      'dateTimeEdited': dateTimeEdited,
      'dateTimeCreated': dateTimeCreated,
      'isFavorite': isFavorite,
      'color': color,
      'isDeleted': isDeleted ?? 0,
      'deletedAt': deletedAt,
    };
  }

  /// Serialise for the note file stored in Google Drive.
  Map<String, dynamic> toDriveJson() {
    return {
      'schemaVersion': 1,
      'syncId': syncId,
      'updatedAt': updatedAt ?? 0,
      'title': title ?? '',
      'content': content ?? '',
      'dateTimeEdited': dateTimeEdited ?? '',
      'dateTimeCreated': dateTimeCreated ?? '',
      'isFavorite': isFavorite ?? 0,
      'color': color ?? '#FFA0A4A8',
      'isDeleted': isDeleted ?? 0,
      'deletedAt': deletedAt,
    };
  }

  /// New local note holding this note's data, used to keep the losing side of
  /// a conflict. The marker is added to [content] because note cards and the
  /// detail page derive the visible title from it.
  Note toConflictCopy() {
    return Note(
      syncId: const Uuid().v4(),
      syncStatus: 'pending',
      updatedAt: updatedAt,
      title: '$title (Conflict copy)',
      content: _prependLine(content, '(Conflict copy)'),
      dateTimeEdited: dateTimeEdited,
      dateTimeCreated: dateTimeCreated,
      isFavorite: isFavorite,
      color: color,
      isDeleted: isDeleted,
      deletedAt: deletedAt,
    );
  }

  static String? _prependLine(String? content, String line) {
    if (content == null) return line;
    try {
      final ops = jsonDecode(content) as List<dynamic>;
      return jsonEncode([
        {'insert': '$line\n'},
        ...ops,
      ]);
    } catch (_) {
      return '$line\n$content';
    }
  }

  DateTime get editedDateTime {
    if (dateTimeEdited == null || dateTimeEdited!.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return parseDate(dateTimeEdited) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime get createdDateTime {
    if (dateTimeCreated == null || dateTimeCreated!.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return parseDate(dateTimeCreated) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Parses ISO-8601 or legacy 'dd-MM-yyyy hh:mm a' date strings.
  static DateTime? parseDate(String? raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      try {
        final parts = raw.trim().split(RegExp(r'\s+'));
        final dateParts = parts[0].split('-');
        final timeParts = parts[1].split(':');
        final isPM = parts.length > 2 && parts[2].toLowerCase() == 'pm';
        final day = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        int hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        if (isPM && hour != 12) hour += 12;
        if (!isPM && hour == 12) hour = 0;
        return DateTime(year, month, day, hour, minute);
      } catch (_) {
        try {
          return DateFormat('dd-MM-yyyy hh:mm a').parse(raw);
        } catch (_) {
          return null;
        }
      }
    }
  }
}
