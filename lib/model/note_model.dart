class Note {
  int? id;
  String? title;
  String? content;
  String? dateTimeEdited;
  String? dateTimeCreated;
  int? isFavorite;
  String? color;

  Note({
    this.id,
    this.title,
    this.content,
    this.dateTimeEdited,
    this.dateTimeCreated,
    this.isFavorite,
    this.color = '#FFA0A4A8',
  });

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
}
