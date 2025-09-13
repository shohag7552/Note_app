class Note {
  int? id;
  String? title;
  String? dateTimeEdited;
  String? dateTimeCreated;
  int? isFavorite;
  String? color;
  String? content;

  Note({
    this.id,
    this.title,
    this.content,
    this.dateTimeEdited,
    this.dateTimeCreated,
    this.isFavorite,
    this.color = '#FFA0A4A8',
  });

  Note.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    content = json['content'];
    dateTimeEdited = json['dateTimeEdited'];
    dateTimeCreated = json['dateTimeCreated'];
    isFavorite = json['isFavorite'];
    color = json['color'];
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "content": content,
      "dateTimeEdited": dateTimeEdited,
      "dateTimeCreated": dateTimeCreated,
      "isFavorite": isFavorite,
      "color": color,
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
