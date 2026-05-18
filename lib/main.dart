import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:my_note_app/theme/dark_theme.dart' show buildDarkTheme;
import 'package:my_note_app/theme/light_theme.dart' show buildLightTheme;
import 'helper/dependency.dart' as di;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-lock the app whenever it returns to foreground and any lock is active.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = Get.find<NoteController>();
    if (state == AppLifecycleState.paused) {
      controller.setSessionUnlocked(false);
    }
    if (state == AppLifecycleState.resumed) {
      if (controller.isSessionUnlocked) return;
      final current = Get.currentRoute;
      final anyLockActive =
          controller.isPasswordActive() || controller.isBiometricLockActive();
      if (anyLockActive &&
          current.isNotEmpty &&
          current != AppRoute.pass &&
          current != AppRoute.forgetPass &&
          current != AppRoute.ADD_NEW_NOTE) {
        Get.offAllNamed(AppRoute.pass);
      }

      // ── Auto-Retry: push any pending notes when app returns to foreground.
      // Also re-checks the Appwrite session and re-authenticates if expired.
      _onAppResumed();
    }
  }

  void _onAppResumed() async {
    try {
      final authCtrl = Get.find<AuthController>();
      if (!authCtrl.isLoggedIn()) return;
      // Ensure Appwrite session is still valid (re-auth silently if expired).
      await authCtrl.ensureSession();
      // Push any notes that were created/edited while offline.
      final email = authCtrl.getUserToken();
      if (email != null) {
        await Get.find<SyncService>().pushAllPending(email);
        // Refresh the notes list to reflect any sync status changes.
        Get.find<NoteController>().getAllNotes();
      }
    } catch (e) {
      print('[main] App resume sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoteController>(
      builder: (noteController) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Note App',
          theme: noteController.darkTheme
              ? buildDarkTheme(noteController.currentFont)
              : buildLightTheme(noteController.currentFont),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          initialRoute: _initialRoute(),
          getPages: AppRoute.getRoutes,
        );
      },
    );
  }

  String _initialRoute() {
    final ctrl = Get.find<NoteController>();
    if (ctrl.isPasswordActive() || ctrl.isBiometricLockActive()) {
      return AppRoute.pass;
    }
    return AppRoute.HOME;
  }
}
