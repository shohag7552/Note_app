import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/screens/note_screens/edit_note_page.dart';
import 'package:my_note_app/database_helper/database_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:my_note_app/widgets/text_edit_widget.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  final String path;
  FakePathProvider(this.path);
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

final _db = DatabaseHelper.instance;

Document _doc(String text) => Document.fromJson([
      {'insert': '$text\n'},
    ]);

/// Pushes the editor on top of a marker page, as the app does.
Future<void> _openEditor(WidgetTester tester, Widget editor) async {
  await tester.pumpWidget(GetMaterialApp(
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    initialRoute: '/under',
    getPages: [
      GetPage(name: '/under', page: () => const Scaffold(body: Text('under'))),
      GetPage(name: AppRoute.HOME, page: () => const Scaffold(body: Text('home'))),
    ],
  ));
  Get.to(() => Scaffold(body: editor));
  await tester.pumpAndSettle();
}

QuillController _controller(WidgetTester tester) =>
    tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;

/// Lets real database work finish between frames.
Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.pumpAndSettle();
}

Future<void> _pressBack(WidgetTester tester) async {
  await tester.runAsync(() => tester.binding.handlePopRoute());
  await _settle(tester);
}

Future<void> _leaveApp(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await _settle(tester);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('note_autosave');
    PathProviderPlatform.instance = FakePathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Get.put(NoteController(sharedPreferences: prefs));
    Get.put(SyncService(isLoggedIn: () => false));
  });

  setUp(() async {
    Get.testMode = true;
    await _db.deleteAllNotes();
  });

  testWidgets('back saves a new note and goes home', (tester) async {
    await _openEditor(tester, const TextEditWidget(readOnly: false, content: null, isAddNote: true));
    _controller(tester).document = _doc('Hello');

    await _pressBack(tester);

    final notes = await tester.runAsync(_db.getNoteList);
    expect(notes!.single.title, 'Hello');
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('back on an empty new note saves nothing', (tester) async {
    await _openEditor(tester, const TextEditWidget(readOnly: false, content: null, isAddNote: true));

    await _pressBack(tester);

    expect(await tester.runAsync(_db.getNoteList), isEmpty);
    expect(find.text('under'), findsOneWidget);
  });

  testWidgets('leaving the app twice with edits between keeps one note', (tester) async {
    await _openEditor(tester, const TextEditWidget(readOnly: false, content: null, isAddNote: true));
    _controller(tester).document = _doc('First');
    await _leaveApp(tester);
    expect((await tester.runAsync(_db.getNoteList))!.single.title, 'First');

    _controller(tester).document = _doc('Second');
    await _leaveApp(tester);

    final notes = await tester.runAsync(_db.getNoteList);
    expect(notes!.single.title, 'Second');
    expect(find.byType(TextEditWidget), findsOneWidget);
  });

  testWidgets('edit screen undo and redo change the text and what gets saved', (tester) async {
    Get.put(BackgroundController(sharedPreferences: Get.find<NoteController>().sharedPreferences));
    final existing = Note(
      title: 'Old',
      content: jsonEncode(_doc('Old').toDelta().toJson()),
      dateTimeEdited: '01-01-2026 10:00 AM',
      dateTimeCreated: '01-01-2026 10:00 AM',
      isFavorite: 0,
      color: '#FF000000',
      syncStatus: 'pending',
    );
    await tester.runAsync(() => _db.addNote(existing));
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      initialRoute: '/under',
      getPages: [
        GetPage(name: '/under', page: () => const Scaffold(body: Text('under'))),
        GetPage(name: AppRoute.HOME, page: () => const Scaffold(body: Text('home'))),
      ],
    ));
    Get.to(() => EditNotePage(note: existing));
    await tester.pumpAndSettle();

    final undo = find.byIcon(Icons.undo_outlined);
    final redo = find.byIcon(Icons.redo_outlined);
    final controller = _controller(tester);
    controller.replaceText(3, 0, ' text', null);
    await tester.pump();
    expect(controller.document.toPlainText(), 'Old text\n');

    await tester.tap(undo.first);
    await tester.pump();
    expect(controller.document.toPlainText(), 'Old\n');

    await tester.tap(redo.first);
    await tester.pump();
    expect(controller.document.toPlainText(), 'Old text\n');

    await tester.tap(undo.first);
    await tester.pump();
    controller.replaceText(0, 0, 'Very ', null);
    await tester.pump();
    await _pressBack(tester);
    expect((await tester.runAsync(_db.getNoteList))!.single.title, 'Very Old');
  });

  testWidgets('back updates an edited note, and unchanged notes are left alone', (tester) async {
    final existing = Note(
      title: 'Old',
      content: jsonEncode(_doc('Old').toDelta().toJson()),
      dateTimeEdited: '01-01-2026 10:00 AM',
      dateTimeCreated: '01-01-2026 10:00 AM',
      isFavorite: 1,
      color: '#FF000000',
      syncStatus: 'pending',
    );
    await tester.runAsync(() => _db.addNote(existing));

    await _openEditor(
      tester,
      TextEditWidget(readOnly: false, content: _doc('Old'), isAddNote: false, note: existing),
    );
    await _pressBack(tester);
    expect((await tester.runAsync(_db.getNoteList))!.single.dateTimeEdited, '01-01-2026 10:00 AM');
    expect(find.text('under'), findsOneWidget);

    await _openEditor(
      tester,
      TextEditWidget(readOnly: false, content: _doc('Old'), isAddNote: false, note: existing),
    );
    _controller(tester).document = _doc('New');
    await _pressBack(tester);

    final saved = (await tester.runAsync(_db.getNoteList))!.single;
    expect(saved.id, existing.id);
    expect(saved.title, 'New');
    expect(saved.isFavorite, 1);
    expect(saved.dateTimeCreated, '01-01-2026 10:00 AM');
    expect(find.text('home'), findsOneWidget);
  });
}
