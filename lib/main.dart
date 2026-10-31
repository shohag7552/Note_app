import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:my_note_app/theme/dark_theme.dart' show buildDarkTheme;
import 'package:my_note_app/theme/light_theme.dart' show buildLightTheme;
import 'package:my_note_app/utils/app_constants.dart';
import 'helper/dependency.dart' as di;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  // Auto-purge trashed notes older than 30 days (fire-and-forget).
  Get.find<NoteController>().purgeExpiredTrash();

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

    final sync = Get.find<SyncService>();
    sync.onDriveAccessNeeded = _showConnectDrivePrompt;
    WidgetsBinding.instance.addPostFrameCallback((_) => sync.syncNow());
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

      // ── Auto-Retry: sync pending notes and pick up changes from other devices.
      Get.find<SyncService>().syncOnResume();
    }
  }

  void _showConnectDrivePrompt() {
    Get.snackbar(
      'Back up your notes',
      'Connect Google Drive to keep your notes safe and on all your devices.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 8),
      mainButton: TextButton(
        onPressed: () {
          Get.closeCurrentSnackbar();
          Get.find<AuthController>().connectDrive();
        },
        child: const Text('Connect'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoteController>(
      builder: (noteController) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppConstants.appName,
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
    final auth = Get.find<AuthController>();
    // Lock screen takes priority
    if (ctrl.isPasswordActive() || ctrl.isBiometricLockActive()) {
      return AppRoute.pass;
    }
    // Brand-new user: not logged in AND no local notes → welcome screen
    if (!auth.isLoggedIn() && ctrl.notes.isEmpty) {
      return AppRoute.WELCOME;
    }
    return AppRoute.HOME;
  }
}
