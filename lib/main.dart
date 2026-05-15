import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/theme/dark_theme.dart' show buildDarkTheme;
import 'package:my_note_app/theme/light_theme.dart' show buildLightTheme;
import 'helper/dependency.dart' as di;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(MyApp(account: Account(Client())));
}

class MyApp extends StatefulWidget {
  final Account account;
  const MyApp({super.key, required this.account});

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
      // App went to background — clear the session so it re-locks on next resume.
      controller.setSessionUnlocked(false);
    }
    if (state == AppLifecycleState.resumed) {
      // Skip re-lock if the user just authenticated (avoids race with biometric
      // dialog dismissal triggering resumed before navigation completes).
      if (controller.isSessionUnlocked) return;
      final current = Get.currentRoute;
      final anyLockActive =
          controller.isPasswordActive() || controller.isBiometricLockActive();
      if (anyLockActive && current.isNotEmpty && current != AppRoute.pass) {
        Get.offAllNamed(AppRoute.pass);
      }
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
