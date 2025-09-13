import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/screens/paper_view_widget.dart';
import 'package:my_note_app/theme/dark_theme.dart';
import 'package:my_note_app/theme/light_theme.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'helper/dependency.dart' as di;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();

  // Client client = Client()
  //     .setEndpoint("https://fra.cloud.appwrite.io/v1")
  //     .setProject("68c477bd0025144ebd1c");
  // Account account = Account(client);

  runApp(MyApp(account: Account(Client())));
}

class MyApp extends StatelessWidget {
  final Account account;
  const MyApp({super.key, required this.account});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetBuilder<NoteController>(
      builder: (noteController) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: "Note App by flutter",
          theme: noteController.darkTheme ? dark : light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          initialRoute: checkPasswordAllow(),
          getPages: AppRoute.getRoutes,
          // home: PageCurlEffectExample(),
        );
      }
    );
  }

  String checkPasswordAllow() {
    if(Get.find<NoteController>().isPasswordActive()) {
      return AppRoute.pass;
    } else {
      return AppRoute.HOME;
    }

  }
}
