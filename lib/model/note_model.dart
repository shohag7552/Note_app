import 'package:intl/intl.dart';

class Note {
  int? id;            // local SQLite primary key
  String? cloudId;    // Appwrite document $id (null when not synced yet)
  String? syncStatus; // 'synced' | 'pending' | 'pendingDelete'
  String? title;
  String? dateTimeEdited;
  String? dateTimeCreated;
  int? isFavorite;
  String? color;
  String? content;
  String? authorEmail;
  int? isDeleted;     // 0 = active, 1 = in recycle bin
  String? deletedAt;  // ISO-8601 timestamp when moved to trash

  Note({
    this.id,
    this.cloudId,
    this.syncStatus = 'synced',
    this.title,
    this.content,
    this.dateTimeEdited,
    this.dateTimeCreated,
    this.isFavorite,
    this.color = '#FFA0A4A8',
    this.authorEmail,
    this.isDeleted = 0,
    this.deletedAt,
  });

  /// Deserialise from local SQLite row.
  Note.fromJson(Map<String, dynamic> json) {
    id = json['note_id'];
    cloudId = json['cloudId'] as String?;
    syncStatus = (json['syncStatus'] as String?) ?? 'synced';
    title = json['title'];
    content = json['content'];
    dateTimeEdited = json['dateTimeEdited'];
    dateTimeCreated = json['dateTimeCreated'];
    isFavorite = json['isFavorite'];
    color = json['color'];
    authorEmail = json['authorEmail'] as String?;
    isDeleted = (json['isDeleted'] as int?) ?? 0;
    deletedAt = json['deletedAt'] as String?;
  }

  /// Deserialise from Appwrite document data.
  factory Note.fromAppwrite(Map<String, dynamic> data, String documentId) {
    return Note(
      cloudId: documentId,
      syncStatus: 'synced',
      title: data['title'] as String?,
      content: data['content'] as String?,
      dateTimeEdited: data['dateTimeEdited'] as String?,
      dateTimeCreated: data['dateTimeCreated'] as String?,
      isFavorite: data['isFavorite'] as int? ?? 0,
      color: data['color'] as String? ?? '#FFA0A4A8',
      authorEmail: data['authorEmail'] as String?,
      isDeleted: data['isDeleted'] as int? ?? 0,
      deletedAt: data['deletedAt'] as String?,
    );
  }

  /// Serialise for local SQLite (includes all local fields).
  Map<String, dynamic> toJson() {
    return {
      'note_id': id,
      'cloudId': cloudId,
      'syncStatus': syncStatus ?? 'synced',
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

  /// Serialise for Appwrite cloud (excludes local-only fields).
  Map<String, dynamic> toCloudMap() {
    return {
      'title': title ?? '',
      'content': content ?? '',
      'dateTimeEdited': dateTimeEdited ?? DateTime.now().toUtc().toIso8601String(),
      'dateTimeCreated': dateTimeCreated ?? DateTime.now().toUtc().toIso8601String(),
      'isFavorite': isFavorite ?? 0,
      'color': color ?? '#FFA0A4A8',
      'isDeleted': isDeleted ?? 0,
      'deletedAt': deletedAt,
      if (authorEmail != null) 'authorEmail': authorEmail,
      if (id != null) 'localId': id,
    };
  }

  Map<String, dynamic> toMapForUpdate() {
    return {
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      'dateTimeEdited': DateTime.now().toUtc().toIso8601String(),
      if (isFavorite != null) 'isFavorite': isFavorite,
      if (color != null) 'color': color,
    };
  }

  DateTime get editedDateTime {
    if (dateTimeEdited == null || dateTimeEdited!.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return _parseDate(dateTimeEdited) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime get createdDateTime {
    if (dateTimeCreated == null || dateTimeCreated!.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return _parseDate(dateTimeCreated) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _parseDate(String? raw) {
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
