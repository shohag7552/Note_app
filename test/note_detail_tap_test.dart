import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/screens/note_screens/edit_note_page.dart';
import 'package:my_note_app/services/sync_service.dart';
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

const _text = 'Hello world';

final _note = Note(
  id: 1,
  title: 'Hello',
  content: jsonEncode([
    {'insert': '$_text\n'},
  ]),
  dateTimeEdited: '01-01-2026 10:00 AM',
  dateTimeCreated: '01-01-2026 10:00 AM',
  isFavorite: 0,
);

Future<void> _openDetail(WidgetTester tester) async {
  await tester.pumpWidget(GetMaterialApp(
    localizationsDelegates: const [
      DefaultMaterialLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
      FlutterQuillLocalizations.delegate,
    ],
    initialRoute: '/under',
    getPages: [
      GetPage(name: '/under', page: () => const Scaffold(body: Text('under'))),
      ...AppRoute.getRoutes,
    ],
  ));
  Get.toNamed(AppRoute.getNoteDetailsPage(_note));
  await tester.pumpAndSettle();
}

QuillController _controller(WidgetTester tester) =>
    tester.widget<QuillEditor>(find.byType(QuillEditor).last).controller;

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = await Directory.systemTemp.createTemp('note_detail_tap');
    PathProviderPlatform.instance = FakePathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Get.put(NoteController(sharedPreferences: prefs));
    Get.put(BackgroundController(sharedPreferences: prefs));
    Get.put(SyncService(isLoggedIn: () => false));
    Get.testMode = true;
  });

  testWidgets('tapping the text opens the editor with the cursor where tapped', (tester) async {
    await _openDetail(tester);
    expect(find.byType(EditNotePage), findsNothing);

    final editor = tester.getTopLeft(find.byType(QuillEditor));
    // Test font glyphs are 14 wide and the lines are 14 or more high.
    await tester.tapAt(editor + const Offset(14 * 6 + 2, 8));
    await tester.pumpAndSettle();

    expect(find.byType(EditNotePage), findsOneWidget);
    final selection = _controller(tester).selection;
    expect(selection.isCollapsed, isTrue);
    expect(selection.baseOffset, inExclusiveRange(0, _text.length));
  });

  testWidgets('tapping the empty space below the text opens the editor at the end', (tester) async {
    await _openDetail(tester);

    final box = tester.getRect(find.byType(QuillEditor));
    await tester.tapAt(Offset(box.left + 5, box.bottom - 40));
    await tester.pumpAndSettle();

    expect(find.byType(EditNotePage), findsOneWidget);
    expect(_controller(tester).selection.baseOffset, _text.length);
  });

  testWidgets('the Edit button opens the editor at the end of the note', (tester) async {
    await _openDetail(tester);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(find.byType(EditNotePage), findsOneWidget);
    expect(_controller(tester).selection.baseOffset, _text.length);
    expect(_controller(tester).readOnly, isFalse);
  });

  testWidgets('going back from the editor keeps the detail screen working', (tester) async {
    await _openDetail(tester);
    await tester.tapAt(tester.getTopLeft(find.byType(QuillEditor)) + const Offset(30, 8));
    await tester.pumpAndSettle();

    await tester.runAsync(() => tester.binding.handlePopRoute());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.byType(EditNotePage), findsNothing);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.byType(EditNotePage), findsOneWidget);
  });
}
