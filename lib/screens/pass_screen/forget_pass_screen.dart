import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class ForgetPassScreen extends StatelessWidget {
  const ForgetPassScreen({super.key});

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
                    Icons.lock_reset_rounded,
                    size: 36,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Set New PIN',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a new 4-digit PIN for ${AppConstants.appName}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _PinResetField(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinResetField extends StatefulWidget {
  @override
  State<_PinResetField> createState() => _PinResetFieldState();
}

class _PinResetFieldState extends State<_PinResetField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PinCodeTextField(
      appContext: context,
      length: 4,
      controller: _controller,
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
        activeColor: theme.colorScheme.onSurface,
        activeFillColor: theme.cardColor,
      ),
      textStyle: theme.textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 2),
      onChanged: (_) {},
      onCompleted: (pin) {
        Get.find<NoteController>().setPassword(pin);
        Get.offAllNamed(AppRoute.HOME);
      },
    );
  }
}
