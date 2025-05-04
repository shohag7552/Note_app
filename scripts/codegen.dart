// scripts/generate_models.dart
import 'dart:io';
import 'package:json_annotation/json_annotation.dart';

void main() {
  // final json = File('lib/data/user.json').readAsStringSync();
  // final model = generateDartClass(json, 'User');
  // File('lib/models/user.dart').writeAsStringSync(model);

  stdout.writeln('Write something to the console: ');
  final input = stdin.readLineSync();
  stdout.writeln('You wrote: $input');
}