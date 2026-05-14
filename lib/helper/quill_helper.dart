import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

class QuillHelper {

  static String convertStringDocumentToString(String document) {
    return Document.fromJson(jsonDecode(document)).toPlainText().toString();
  }

  /// Derives `(title, body)` from a Quill document JSON string.
  /// The first non-empty line is the title; remaining lines are the body.
  static (String title, String body) deriveTitleAndBody(String? rawContent) {
    if (rawContent == null || rawContent.isEmpty) return ('Untitled', '');
    String plain;
    try {
      plain = Document.fromJson(jsonDecode(rawContent)).toPlainText().trim();
    } catch (_) {
      plain = rawContent.trim();
    }
    if (plain.isEmpty) return ('Untitled', '');
    final lines = plain
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return ('Untitled', '');
    return (lines.first, lines.skip(1).join('\n').trim());
  }
}
