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
      if (authorEmail != null) 'authorEmail': authorEmail,
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
}
