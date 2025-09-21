import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_note_app/model/user_model.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;
  AuthController({required this.sharedPreferences});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  );

  Future<void> googleLogin() async {
    _isLoading = true;
    update();

    GoogleSignInAccount googleAccount = (await _googleSignIn.signIn())!;
    GoogleSignInAuthentication auth = await googleAccount.authentication;

    print('====google data : ${googleAccount.email} // ${googleAccount.id} // ${googleAccount.displayName}'
    '//auth accessToken: ${auth.accessToken} // idToken: ${auth.idToken}');
    await sharedPreferences.setString(AppConstants.authKey, googleAccount.email);
    await sharedPreferences.setString(AppConstants.authName, googleAccount.displayName ?? '');
    await sharedPreferences.setString(AppConstants.authImage, googleAccount.photoUrl ?? '');
    print('=======set auth email : ${googleAccount.email}');
    _isLoading = false;
    update();
  }

  void googleLogOut() async {
    try {
      await _googleSignIn.signOut();
      await sharedPreferences.remove(AppConstants.authKey);
      await sharedPreferences.remove(AppConstants.authName);
      await sharedPreferences.remove(AppConstants.authImage);
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

  UserModel? getUser() {
    return UserModel(
      name: sharedPreferences.getString(AppConstants.authName) ?? '',
      email: sharedPreferences.getString(AppConstants.authKey) ?? '',
      imageUrl: sharedPreferences.getString(AppConstants.authImage) ?? '',
    );
  }
}