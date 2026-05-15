import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ForgetPassScreen extends StatefulWidget {
  const ForgetPassScreen({super.key});

  @override
  State<ForgetPassScreen> createState() => _ForgetPassScreenState();
}

class _ForgetPassScreenState extends State<ForgetPassScreen> {
  final _pinController = TextEditingController();
  String? _newPinBuffer;
  bool _confirmingNewPin = false;
  bool _pinError = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  void _onPinCompleted(String pin) {
    if (!_confirmingNewPin) {
      // First entry: buffer it and ask to confirm
      _newPinBuffer = pin;
      _pinController.clear();
      setState(() {
        _confirmingNewPin = true;
        _pinError = false;
      });
    } else {
      // Confirm entry
      if (pin == _newPinBuffer) {
        final ctrl = Get.find<NoteController>();
        ctrl.setPassword(pin);
        ctrl.setSessionUnlocked(true);
        Get.offAllNamed(AppRoute.HOME);
      } else {
        _pinController.clear();
        _newPinBuffer = null;
        setState(() {
          _confirmingNewPin = false;
          _pinError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Icon(
                    _confirmingNewPin
                        ? Icons.lock_outline_rounded
                        : Icons.lock_reset_rounded,
                    size: 36,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(_confirmingNewPin),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _confirmingNewPin ? 'Confirm your PIN' : 'Set New PIN',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _confirmingNewPin
                            ? 'Re-enter your PIN to confirm'
                            : 'Choose a new 4-digit PIN for ${AppConstants.appName}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                PinCodeTextField(
                  appContext: context,
                  length: 4,
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.scale,
                  animationDuration: const Duration(milliseconds: 180),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: true,
                  autoFocus: true,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(14),
                    fieldHeight: 60,
                    fieldWidth: 54,
                    borderWidth: 1.5,
                    inactiveColor: theme.dividerColor,
                    inactiveFillColor: theme.cardColor,
                    selectedColor: theme.colorScheme.onSurface,
                    selectedFillColor: theme.cardColor,
                    activeColor: _pinError
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface,
                    activeFillColor: _pinError
                        ? theme.colorScheme.error.withValues(alpha: 0.06)
                        : theme.cardColor,
                  ),
                  textStyle: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 2),
                  onChanged: (e) {
                    print('pin changed: $e');
                    if (_pinError) setState(() => _pinError = false);
                  },
                  onCompleted: _onPinCompleted,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _pinError
                      ? Padding(
                          key: const ValueKey('err'),
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'PINs do not match. Try again.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('no-err'), height: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
