import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:my_note_app/widgets/background_color_opacity_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundController extends GetxController implements GetxService {
  final SharedPreferences sharedPreferences;

  BackgroundController({required this.sharedPreferences}) {
    _getBackgroundImage();
  }

  XFile? _image;
  XFile? get backgroundImage => _image;
  //
  // double _colorOpacity = 0.1;
  // double get colorOpacity => _colorOpacity = 0.1;

  Future<XFile?> pickBackgroundImage({bool isRemove = false}) async {
    if(isRemove) {
      _image = null;
    } else {
      final ImagePicker picker = ImagePicker();
      _image = await picker.pickImage(source: ImageSource.gallery);

      if(_image != null) {
        // Save the image path to shared preferences
        await sharedPreferences.setString(AppConstants.backgroundImageKey, _image!.path);
      }
      // Get.dialog(BackgroundColorOpacityDialog(), barrierColor: Colors.transparent).then((v) {
      //   print('====tttt===> $v');
      //   _colorOpacity = v;
      // });
      // showDialog(
      //     context: Get.context!,
      //     builder: (BuildContext context) {
      //       return BackgroundColorOpacityDialog();
      //     });
    }

    update();
    return _image;
  }

  // void setOpacity(double value) {
  //   _colorOpacity = value;
  //
  //   Future.delayed(Duration(milliseconds: 600), () {
  //     update();
  //   });
  //
  //   print('======opacity: $_colorOpacity');
  // }

  void setOpacity(double value) {
    sharedPreferences.setDouble(AppConstants.opacityKey, value);
  }

  double getOpacity() {
    return sharedPreferences.getDouble(AppConstants.opacityKey) ?? 0.1;
  }

  void _getBackgroundImage() {
    String? savedImagePath = sharedPreferences.getString(AppConstants.backgroundImageKey);
    if (savedImagePath != null && savedImagePath.isNotEmpty) {
      _image = XFile(savedImagePath);
    } else {
      _image = null;
    }
    update();
  }


}