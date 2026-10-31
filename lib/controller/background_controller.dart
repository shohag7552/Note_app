import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rebuild target for note screens. Sync logic lives in SyncService.
class BackgroundController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  BackgroundController({required this.sharedPreferences});
}
