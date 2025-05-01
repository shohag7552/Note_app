import 'dart:io';
import 'package:path/path.dart' as path;

class FolderGenerator {
  static final Map<String, String> _templates = {
    'bloc': '''
import 'package:flutter_bloc/flutter_bloc.dart';

class {className}Bloc extends Bloc<{className}Event, {className}State> {
  {className}Bloc() : super({className}Initial());
}
''',
    'screen': '''
import 'package:flutter/material.dart';

class {className}Screen extends StatelessWidget {
  const {className}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('{className} Screen')),
    );
  }
}
''',
  };

  static void generate(String folderName, String structureType) {
    final libDir = Directory('lib');
    final newDir = Directory(path.join(libDir.path, folderName));

    // Create folder
    newDir.createSync(recursive: true);
    print('📁 Created folder: ${newDir.path}');

    // Generate files based on template
    switch (structureType) {
      case 'bloc':
        _generateBlocFiles(newDir, folderName);
        break;
      case 'screen':
        _generateScreenFiles(newDir, folderName);
        break;
      default:
        throw Exception('Unknown structure type: $structureType');
    }
  }

  static void _generateBlocFiles(Directory dir, String name) {
    final className = _toPascalCase(name);
    
    File(path.join(dir.path, '${name}_bloc.dart'))
      .writeAsStringSync(_templates['bloc']!.replaceAll('{className}', className));
    
    File(path.join(dir.path, '${name}_event.dart'))
      .writeAsStringSync('''
abstract class ${className}Event {}
class Load${className}Event extends ${className}Event {}
''');

    File(path.join(dir.path, '${name}_state.dart'))
      .writeAsStringSync('''
abstract class ${className}State {}
class ${className}Initial extends ${className}State {}
''');
  }

  static void _generateScreenFiles(Directory dir, String name) {
    final className = _toPascalCase(name);
    File(path.join(dir.path, '${name}_screen.dart'))
      .writeAsStringSync(_templates['screen']!.replaceAll('{className}', className));
  }

  static String _toPascalCase(String input) {
    return input.split('_').map((s) => s[0].toUpperCase() + s.substring(1)).join();
  }
}