import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/drive/drive_repository.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/screens/home_page.dart';
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

/// A Drive whose listing never finishes, so the app stays in its syncing state.
class HangingDrive extends DriveRepository {
  HangingDrive() : super(clientProvider: ({bool forceRefresh = false}) => throw UnimplementedError());
  final hold = Completer<List<RemoteFile>>();
  @override
  Future<List<RemoteFile>> listFiles() => hold.future;
}

void main() {
  testWidgets('title fits while syncing on a narrow phone', (tester) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dir = (await tester.runAsync(() => Directory.systemTemp.createTemp('home_app_bar')))!;
    PathProviderPlatform.instance = FakePathProvider(dir.path);
    SharedPreferences.setMockInitialValues({});
    final prefs = (await tester.runAsync(SharedPreferences.getInstance))!;
    final notes = Get.put(NoteController(sharedPreferences: prefs));
    Get.put(BackgroundController(sharedPreferences: prefs));
    Get.put(AuthController(sharedPreferences: prefs));
    final drive = HangingDrive();
    final sync = Get.put(SyncService(repository: drive, isLoggedIn: () => true));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    notes.notes = [
      for (var i = 0; i < 1234; i++)
        Note(id: i, title: 't', content: '[{"insert":"t\\n"}]', dateTimeEdited: '01-01-2026 10:00 AM',
            dateTimeCreated: '01-01-2026 10:00 AM', isFavorite: 0, color: '#FF000000'),
    ];

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      home: const HomePage(),
    ));
    unawaited(sync.syncNow());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(sync.isSyncing, isTrue);
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(tester.takeException(), isNull);

    // A typical phone doesn't overflow either.
    tester.view.physicalSize = const Size(360, 640);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
