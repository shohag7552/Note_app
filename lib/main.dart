import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:notes_app/firebase_options.dart';
import 'package:notes_app/routing/app_routes.dart';
import 'package:notes_app/theme/light_theme.dart';
import 'helper/dependency.dart' as di;

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
    ));
    return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Note App by flutter",
        theme: light,
        initialRoute: AppRoute.DASHBOARD,
        getPages: AppRoute.getRoutes,
    );
  }
}
