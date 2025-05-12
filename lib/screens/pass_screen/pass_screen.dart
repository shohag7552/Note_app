import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/utils/style.dart';
import 'package:my_note_app/widgets/toast.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PassScreen extends StatefulWidget {
  const PassScreen({super.key});

  @override
  State<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> {

  String code = '1234';

  String? enterCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: GetBuilder<NoteController>(
        builder: (noteController) {
          bool alreadyHavePassword = noteController.isContainPassword();

          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            Text(
              !alreadyHavePassword ? 'Please setup your password' : 'Please enter your correct password',
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
                }
              },
              child: Text(alreadyHavePassword ? 'Verify' : 'Set'),
            ),
          ]);
        }
      ),
    );
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
