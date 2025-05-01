// scripts/folder_generator/bin/generator.dart
// #!/usr/bin/env dart
import 'dart:io';

import 'package:args/args.dart';

import '../lib/generator.dart';
// import 'package:folder_generator/generator.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('name', abbr: 'n', help: 'Folder/module name (e.g., "user_profile")')
    ..addOption('type', abbr: 't', help: 'Structure type (bloc|screen)', defaultsTo: 'bloc');

// dart run bin/generator.dart --name=test --type=screen    
  try {
    final results = parser.parse(args);
    final folderName = results['name'];
    final structureType = results['type'];

    if (folderName == null) {
      throw Exception('Folder name is required (use --name)');
    }

    FolderGenerator.generate(folderName, structureType);
    print('✅ Successfully generated $folderName ($structureType)');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}