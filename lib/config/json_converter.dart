import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class JsonFile {
  static getFullPath(String dirPath, String fileName) {
    return '$dirPath/$fileName.json';
  }

  static Future<String?> readFileAsJson(
      {String? dirPath, String? fileName}) async {
    if (dirPath == null || fileName == null) {
      return null;
    }
    final path = getFullPath(dirPath, fileName);
    final file = File(path);
    return await file.readAsString();
  }

  static Future<String> streamToJson(Stream stream,
      {String? dirPath, String? fileName}) async {
    List<int> dataList = [];
    final subscription = stream.listen(
            (data) {
          dataList.insertAll(dataList.length, data);
        },
        onDone: () {},
        onError: (error) {
          if (kDebugMode) {
            throw Exception(error.toString());
          }
        });
    final subscriptionAsFuture = subscription.asFuture();
    await Future.wait([subscriptionAsFuture]);
    return await (File(
        '${dirPath ?? (await getTemporaryDirectory()).path}/${fileName ?? 'temp-${DateTime.now().millisecondsSinceEpoch}'}.json')
      ..writeAsBytes(dataList))
        .readAsString();
  }

  static Future<File> stringToJsonFile(String data,
      {String? dirPath, String? fileName}) async {
    final dir = await getTemporaryDirectory();
    final path = getFullPath(dirPath ?? dir.path,
        fileName ?? 'temp-${DateTime.now().millisecondsSinceEpoch}');
    final file = File(path);
    await file.writeAsString(data);
    return file;
  }
}