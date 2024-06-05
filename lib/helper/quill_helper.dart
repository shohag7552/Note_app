import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

class QuillHelper {

  static String convertStringDocumentToString(String document) {
    return Document.fromJson(jsonDecode(document)).toPlainText().toString();
  }
}