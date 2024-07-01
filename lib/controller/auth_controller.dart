import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:notes_app/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  AuthController({required this.sharedPreferences});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> googleLogin(GoogleSignIn googleSignIn) async {
    _isLoading = true;
    update();

    GoogleSignInAccount googleAccount = (await googleSignIn.signIn())!;
    GoogleSignInAuthentication auth = await googleAccount.authentication;

    print('====google data : ${googleAccount.email} // ${googleAccount.id} // ${googleAccount.displayName}'
    '//auth accessToken: ${auth.accessToken} // idToken: ${auth.idToken}');
    await sharedPreferences.setString(AppConstants.authKey, googleAccount.email);
    print('=======set auth email : ${googleAccount.email}');
    _isLoading = false;
    update();
  }

  void googleLogOut(GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.signOut();
      await sharedPreferences.remove(AppConstants.authKey);
      print('==log out');
    } catch (error) {
      print(error);
    }
    update();
  }

  String? getUserToken() {
    if(sharedPreferences.containsKey(AppConstants.authKey)) {
     return sharedPreferences.getString(AppConstants.authKey);
    }
    return null;
  }
}