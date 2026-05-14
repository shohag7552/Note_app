import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

enum _Mode { verify, setupQuestions, createPin, forgotPin }

class PassScreen extends StatefulWidget {
  const PassScreen({super.key});

  @override
  State<PassScreen> createState() => _PassScreenState();
}

class _PassScreenState extends State<PassScreen> {
  final _localAuth = LocalAuthentication();
  final _answerController = TextEditingController();
  final _pinController = TextEditingController();

  late _Mode _mode;
  bool _biometricAvailable = false;
  bool _pinError = false;

  // Security-question setup
  int _questionIndex = 0;
  final List<String> _collectedAnswers = [];

  // Forgot PIN — show a random question
  late int _randomQuestionIndex;

  static const _questions = [
    'What is your favourite hobby?',
    "What is your pet's name?",
    "What is your mother's maiden name?",
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _randomQuestionIndex = Random().nextInt(_questions.length);
    final hasPin = Get.find<NoteController>().isContainPassword();
    _mode = hasPin ? _Mode.verify : _Mode.setupQuestions;
    if (_mode == _Mode.verify) _initBiometrics();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ── Biometrics ────────────────────────────────────────────────────────────
  Future<void> _initBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!mounted) return;
      setState(() => _biometricAvailable = canCheck && isSupported);
      if (_biometricAvailable) _triggerBiometric();
    } catch (_) {}
  }

  Future<void> _triggerBiometric() async {
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your notes',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok && mounted) Get.offAllNamed(AppRoute.HOME);
    } on PlatformException {
      // Biometric failed / cancelled — fall back to PIN silently.
    }
  }

  // ── PIN verify ────────────────────────────────────────────────────────────
  void _verifyPin(String pin) {
    final ok = Get.find<NoteController>().verifyPassword(pin);
    if (ok) {
      Get.offAllNamed(AppRoute.HOME);
    } else {
      _pinController.clear();
      setState(() => _pinError = true);
    }
  }

  // ── Security-question setup ───────────────────────────────────────────────
  void _submitAnswer() {
    _collectedAnswers.add(_answerController.text.trim().toLowerCase());
    _answerController.clear();
    if (_collectedAnswers.length == _questions.length) {
      Get.find<NoteController>().setSuggestions(_collectedAnswers);
    }
    setState(() {
      _questionIndex++;
      if (_questionIndex >= _questions.length) _mode = _Mode.createPin;
    });
  }

  // ── Forgot-PIN verify ─────────────────────────────────────────────────────
  Future<void> _verifySecurityAnswer() async {
    final stored = await Get.find<NoteController>().getSuggestions();
    if (!mounted) return;

    final expected = stored?[_randomQuestionIndex].trim().toLowerCase() ?? '';
    final given = _answerController.text.trim().toLowerCase();

    if (expected == given) {
      _answerController.clear();
      Get.offNamed(AppRoute.forgetPass);
    } else {
      final errorColor = Theme.of(context).colorScheme.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect answer. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _Mode.verify => _buildVerify(context),
      _Mode.setupQuestions => _buildSetupQuestions(context),
      _Mode.createPin => _buildCreatePin(context),
      _Mode.forgotPin => _buildForgotPin(context),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN: Verify PIN
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVerify(BuildContext context) {
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
                _lockIcon(theme, Icons.lock_outline_rounded),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your 4-digit PIN',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 40),
                _pinField(
                  context,
                  controller: _pinController,
                  hasError: _pinError,
                  onChanged: (_) {
                    if (_pinError) setState(() => _pinError = false);
                  },
                  onCompleted: _verifyPin,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _pinError
                      ? Padding(
                          key: const ValueKey('err'),
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Incorrect PIN. Try again.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : const SizedBox(key: ValueKey('no-err'), height: 12),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    _mode = _Mode.forgotPin;
                    _pinError = false;
                    _pinController.clear();
                  }),
                  child: Text(
                    'Forgot PIN?',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.hintColor,
                    ),
                  ),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 32),
                  Row(children: [
                    Expanded(child: Divider(color: theme.dividerColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.hintColor)),
                    ),
                    Expanded(child: Divider(color: theme.dividerColor)),
                  ]),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _triggerBiometric,
                    icon: const Icon(Icons.fingerprint_rounded, size: 22),
                    label: const Text('Use Biometrics'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      side: BorderSide(color: theme.dividerColor),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN: Security-question setup (step 1–3)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSetupQuestions(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step progress bar
              Row(
                children: List.generate(_questions.length, (i) {
                  final active = i <= _questionIndex;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: EdgeInsets.only(
                          right: i < _questions.length - 1 ? 6 : 0),
                      height: 4,
                      decoration: BoxDecoration(
                        color: active
                            ? theme.colorScheme.onSurface
                            : theme.dividerColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 36),
              Text(
                'Security Setup',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Answer these to recover your PIN if you ever forget it.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'Question ${_questionIndex + 1} of ${_questions.length}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.hintColor,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _questions[_questionIndex],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _answerController,
                autofocus: true,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(hintText: 'Your answer'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_answerController.text.trim().isNotEmpty) _submitAnswer();
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _answerController.text.trim().isEmpty
                      ? null
                      : _submitAnswer,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.dividerColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    _questionIndex < _questions.length - 1 ? 'Next' : 'Continue',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN: Create PIN (step 4 of setup)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCreatePin(BuildContext context) {
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
                _lockIcon(theme, Icons.lock_open_rounded),
                const SizedBox(height: 24),
                Text(
                  'Create your PIN',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a 4-digit PIN to protect your notes',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _pinField(
                  context,
                  controller: _pinController,
                  hasError: false,
                  onChanged: (_) {},
                  onCompleted: (pin) {
                    Get.find<NoteController>().setPassword(pin);
                    Get.offAllNamed(AppRoute.HOME);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN: Forgot PIN (security-question answer)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildForgotPin(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => setState(() {
            _mode = _Mode.verify;
            _answerController.clear();
          }),
        ),
        title: Text(
          'Forgot PIN',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Answer your security question',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                _questions[_randomQuestionIndex],
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _answerController,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Your answer'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (_answerController.text.trim().isNotEmpty) {
                  _verifySecurityAnswer();
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _answerController.text.trim().isEmpty
                    ? null
                    : _verifySecurityAnswer,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor: theme.dividerColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  'Verify',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared helpers
  // ─────────────────────────────────────────────────────────────────────────
  Widget _lockIcon(ThemeData theme, IconData icon) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: theme.cardColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Icon(icon, size: 36, color: theme.colorScheme.onSurface),
    );
  }

  Widget _pinField(
    BuildContext context, {
    required TextEditingController controller,
    required bool hasError,
    required void Function(String) onChanged,
    required void Function(String) onCompleted,
  }) {
    final theme = Theme.of(context);
    return PinCodeTextField(
      appContext: context,
      length: 4,
      controller: controller,
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
        activeColor: hasError
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface,
        activeFillColor: hasError
            ? theme.colorScheme.error.withValues(alpha: 0.06)
            : theme.cardColor,
      ),
      textStyle: theme.textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 2),
      onChanged: onChanged,
      onCompleted: onCompleted,
    );
  }
}
