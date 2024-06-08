import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:notes_app/controller/auth_controller.dart';
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Auth')),
      body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

        Center(
          child: TextButton(
            onPressed: (){
              Get.find<AuthController>().upload();
            },
            child: const Text('Google Sign in'),
          ),
        ),
      ]),
    );
  }
}
