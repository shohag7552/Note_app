import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/utils/padding_size.dart';
import 'package:my_note_app/utils/style.dart';
import 'package:my_note_app/widgets/toast.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../routing/app_routes.dart';
class ForgetPassScreen extends StatefulWidget {
  const ForgetPassScreen({super.key});

  @override
  State<ForgetPassScreen> createState() => _ForgetPassScreenState();
}

class _ForgetPassScreenState extends State<ForgetPassScreen> {
  String? enterCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

        Text(
          'Please setup your new password',
          style: fontStyleMedium.copyWith(fontSize: 20, color: Theme.of(context).cardColor),
        ),
        SizedBox(height: 50),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: PinCodeTextField(
            length: 4,
            appContext: context,
            keyboardType: TextInputType.number,
            animationType: AnimationType.slide,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              fieldHeight: 60,
              fieldWidth: 55,
              borderWidth: 1,
              borderRadius: BorderRadius.circular(15),
              selectedColor: Theme.of(context).cardColor,
              selectedFillColor: Colors.white,
              inactiveFillColor: Colors.white,
              inactiveColor: Theme.of(context).primaryColor,
              activeColor: Theme.of(context).primaryColor,
              activeFillColor: Colors.white,
            ),
            animationDuration: const Duration(milliseconds: 300),
            backgroundColor: Colors.transparent,
            enableActiveFill: true,
            onChanged: (v) {
              setState(() {
                enterCode = v;
              });
            },
            beforeTextPaste: (text) => true,
          ),
        ),

        SizedBox(height: 50),

        ElevatedButton(
          onPressed: (){
            if(enterCode == null || enterCode!.isEmpty) {
              showToast(message: 'Please Enter Password');
            } else {
              Get.find<NoteController>().setPassword(enterCode!);
              Get.offNamed(AppRoute.HOME);
            }
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(150, 40),
          ),
          child: Text('Set New Password'),
        ),
        const SizedBox(height: PaddingSize.medium),

      ]),
    );
  }
}
