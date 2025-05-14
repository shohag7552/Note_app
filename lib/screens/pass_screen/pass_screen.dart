import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:my_note_app/utils/font_size.dart';
import 'package:my_note_app/utils/padding_size.dart';
import 'package:my_note_app/utils/style.dart';
import 'package:my_note_app/widgets/toast.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:math';

class PassScreen extends StatefulWidget {
  const PassScreen({super.key});

  @override
  State<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> {

  String code = '1234';

  String? enterCode;
  bool alreadyHavePassword = false;

  final TextEditingController _textController = TextEditingController();

  List<String> questions = [
    'What is your favourite hobby?',
    'What is your pet\'s name?',
    'What is your spouse name?',
  ];

  int questionIndex = 0;
  int randomQuestionIndex = 0;

  List<String> answerList = [];

  bool isForgetPassword = false;
  List<String>? suggestion;

  bool takePassAgain = false;

  @override
  void initState() {
    super.initState();

    alreadyHavePassword = Get.find<NoteController>().isContainPassword();
    randomQuestionIndex = generateRandom(0, questions.length);
    initConfig();
  }

  initConfig() async {
    suggestion = await Get.find<NoteController>().getSuggestions();
    print('=========suggestion: $suggestion');
  }

  @override
  void dispose() {

    _textController.dispose();
    super.dispose();
  }

  int generateRandom(int min, int max) {
    final random = Random();
    return min + random.nextInt(max - min + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        child: GetBuilder<NoteController>(
          builder: (noteController) {

            // if(!takePassAgain) {
              alreadyHavePassword = noteController.isContainPassword();
            // }

            return isForgetPassword ? forgetPassView()
                : !alreadyHavePassword ? createAccount()
                : passwordView(noteController);
          }
        ),
      ),
    );
  }

  Widget forgetPassView() {
    return Padding(
      padding: const EdgeInsets.all(PaddingSize.small),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Text(
          "Write the proper answer that you provided while creating password.",
          style: fontStyleMedium.copyWith(fontSize: FontSize.medium),
        ),

        askQuestion(questions[randomQuestionIndex], fromForgetPass: true),
      ]),
    );
  }

  Widget createAccount() {
    return Padding(
      padding: const EdgeInsets.all(PaddingSize.small),
      child: questions.length == questionIndex ? passwordView(Get.find<NoteController>()) : Column(spacing: PaddingSize.small, children: [
        const SizedBox(height: 50),

        Text(
          'Welcome to ${AppConstants.appName}. Please provide some information for Setup your password. ',
          style: fontStyleMedium.copyWith(fontSize: FontSize.medium, color: Theme.of(context).cardColor),
        ),


        Text(
          "You'll reset your password with the help of these information. So please provide valid information.",
          style: fontStyleMedium.copyWith(fontSize: FontSize.small, color: Colors.amber),
        ),

        const SizedBox(height: PaddingSize.large),

        askQuestion(questions[questionIndex]),


      ]),
    );
  }

  Widget askQuestion(String question, {bool fromForgetPass = false}) {
    bool isAllAnswerSubmitted = questions.length == questionIndex;
    return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(
        'Q. $question',
        style: fontStyleMedium.copyWith(fontSize: FontSize.mediumLarge, color: Theme.of(context).cardColor),
      ),

      Row(children: [
        Text(
          'Ans: ',
          style: fontStyleMedium.copyWith(fontSize: FontSize.mediumLarge, color: Colors.amber),
        ),
        Expanded(
          child: TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Write your answer..',
              focusColor: Theme.of(context).cardColor,
              focusedBorder: UnderlineInputBorder(),
              hintStyle: fontStyleNormal.copyWith(color: Colors.black38),
            ),
            onChanged: (v) {
              setState(() {

              });
            },
          ),
        ),
      ]),
      const SizedBox(height: PaddingSize.medium),

      Center(
        child: _textController.text.isNotEmpty ? ElevatedButton(
          style: ElevatedButton.styleFrom(
            shadowColor: Colors.black45,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32.0)),
            minimumSize: const Size(150, 40),
          ),
          onPressed: () async {
            if(!fromForgetPass) {
              answerList.add(_textController.text);
              print('===yyyyy==> $answerList // $isAllAnswerSubmitted');
              _textController.text = '';
              if (!isAllAnswerSubmitted) {
                questionIndex++;
                if(answerList.length == questions.length) {
                  Get.find<NoteController>().setSuggestions(answerList);
                }
              }/* else {
                print('===xxxx==> $answerList');
                Get.find<NoteController>().setSuggestions(answerList);
              }*/
              setState(() {});
            } else {
              suggestion = await Get.find<NoteController>().getSuggestions();
              print('====s : $suggestion');
              if(suggestion != null && suggestion![randomQuestionIndex] == _textController.text) {
                setState(() {
                  isForgetPassword = false;
                  alreadyHavePassword = false;
                  takePassAgain = true;
                });
              } else {
                showToast(message: 'Not matched any answer');
              }
            }
          },
          child: Text('Submit'),
        ) : const SizedBox(),
      ),

    ]);
  }

  Widget passwordView(NoteController noteController) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [

      Text(
        !alreadyHavePassword ? 'Please setup your password' : 'Please enter your password',
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
          } else if(alreadyHavePassword) {
            if(enterCode == noteController.getPassword()) {
              Get.offNamed(AppRoute.HOME);
            } else {
              showToast(message: 'Your password is wrong');
            }
          } else {
            noteController.setPassword(enterCode!);
            Get.offNamed(AppRoute.HOME);
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(150, 40),
        ),
        child: Text(alreadyHavePassword ? 'Verify' : 'Set'),
      ),
      const SizedBox(height: PaddingSize.medium),

      alreadyHavePassword ? TextButton(
        onPressed: (){
          setState(() {
            isForgetPassword = true;
          });
        },
        child: Text('Forget password?', style: fontStyleNormal),
      ) : const SizedBox(),
    ]);
  }
}

/*class _PassScreenState extends State<PassScreen> {

  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  bool? _canCheckBiometrics;
  List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  bool _isAuthenticating = false;

  @override
  void initState() {
  super.initState();
  auth.isDeviceSupported().then(
  (bool isSupported) => setState(() => _supportState = isSupported
  ? _SupportState.supported
      : _SupportState.unsupported),
  );
  }

  Future<void> _checkBiometrics() async {
  late bool canCheckBiometrics;
  try {
  canCheckBiometrics = await auth.canCheckBiometrics;
  } on PlatformException catch (e) {
  canCheckBiometrics = false;
  print(e);
  }
  if (!mounted) {
  return;
  }

  setState(() {
  _canCheckBiometrics = canCheckBiometrics;
  });
  }

  Future<void> _getAvailableBiometrics() async {
  late List<BiometricType> availableBiometrics;
  try {
  availableBiometrics = await auth.getAvailableBiometrics();
  } on PlatformException catch (e) {
  availableBiometrics = <BiometricType>[];
  print(e);
  }
  if (!mounted) {
  return;
  }

  setState(() {
  _availableBiometrics = availableBiometrics;
  });
  }

  Future<void> _authenticate() async {
  bool authenticated = false;
  try {
  setState(() {
  _isAuthenticating = true;
  _authorized = 'Authenticating';
  });
  authenticated = await auth.authenticate(
  localizedReason: 'Let OS determine authentication method',
  options: const AuthenticationOptions(
  // stickyAuth: true,
  ),
  );
  print('====d=d===> $authenticated');
  setState(() {
  _isAuthenticating = false;
  });
  } on PlatformException catch (e) {
  print(e);
  setState(() {
  _isAuthenticating = false;
  _authorized = 'Error - ${e.message}';
  });
  return;
  }
  if (!mounted) {
  return;
  }

  setState(
  () => _authorized = authenticated ? 'Authorized' : 'Not Authorized');
  }

  Future<void> _authenticateWithBiometrics() async {
  bool authenticated = false;
  try {
  setState(() {
  _isAuthenticating = true;
  _authorized = 'Authenticating';
  });
  authenticated = await auth.authenticate(
  localizedReason:
  'Scan your fingerprint (or face or whatever) to authenticate',
  options: const AuthenticationOptions(
  stickyAuth: true,
  biometricOnly: true,
  ),
  );
  setState(() {
  _isAuthenticating = false;
  _authorized = 'Authenticating';
  });
  } on PlatformException catch (e) {
  print(e);
  setState(() {
  _isAuthenticating = false;
  _authorized = 'Error - ${e.message}';
  });
  return;
  }
  if (!mounted) {
  return;
  }

  final String message = authenticated ? 'Authorized' : 'Not Authorized';
  setState(() {
  _authorized = message;
  });
  }

  Future<void> _cancelAuthentication() async {
  await auth.stopAuthentication();
  setState(() => _isAuthenticating = false);
  }

  @override
  Widget build(BuildContext context) {
  return MaterialApp(
  home: Scaffold(
  appBar: AppBar(
  title: const Text('Plugin example app'),
  ),
  body: ListView(
  padding: const EdgeInsets.only(top: 30),
  children: <Widget>[
  Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: <Widget>[
  if (_supportState == _SupportState.unknown)
  const CircularProgressIndicator()
  else if (_supportState == _SupportState.supported)
  const Text('This device is supported')
  else
  const Text('This device is not supported'),
  const Divider(height: 100),
  Text('Can check biometrics: $_canCheckBiometrics\n'),
  ElevatedButton(
  onPressed: _checkBiometrics,
  child: const Text('Check biometrics'),
  ),
  const Divider(height: 100),
  Text('Available biometrics: $_availableBiometrics\n'),
  ElevatedButton(
  onPressed: _getAvailableBiometrics,
  child: const Text('Get available biometrics'),
  ),
  const Divider(height: 100),
  Text('Current State: $_authorized\n'),
  if (_isAuthenticating)
  ElevatedButton(
  onPressed: _cancelAuthentication,
  child: const Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
  Text('Cancel Authentication'),
  Icon(Icons.cancel),
  ],
  ),
  )
  else
  Column(
  children: <Widget>[
  ElevatedButton(
  onPressed: _authenticate,
  child: const Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
  Text('Authenticate'),
  Icon(Icons.perm_device_information),
  ],
  ),
  ),
  ElevatedButton(
  onPressed: _authenticateWithBiometrics,
  child: Row(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
  Text(_isAuthenticating
  ? 'Cancel'
      : 'Authenticate: biometrics only'),
  const Icon(Icons.fingerprint),
  ],
  ),
  ),
  ],
  ),
  ],
  ),
  ],
  ),
  ),
  );
  }
  }*/

  // enum _SupportState {
  // unknown,
  // supported,
  // unsupported,
  // }
