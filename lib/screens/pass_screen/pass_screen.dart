import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

enum _Mode {
  verify,
  biometricOnly,
  setupQuestions,
  createPin,
  forgotPin,
  changePinVerify,
  changePinCreate,
  changeQuestionsOnly,
}

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
  bool _pinError = false;
  bool _fromSettings = false;

  // Security-question setup
  int _questionIndex = 0;
  final List<String> _collectedAnswers = [];

  // Forgot PIN — show a random question
  late int _randomQuestionIndex;

  // Two-step PIN confirmation (create & change flows)
  String? _newPinBuffer;
  bool _confirmingNewPin = false;

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

    final args = Get.arguments as Map<String, dynamic>?;
    final intent = args?['intent'] as String?;
    _fromSettings = intent != null;

    final ctrl = Get.find<NoteController>();
    final hasPin = ctrl.isContainPassword();

    if (intent == 'changePin') {
      _mode = _Mode.changePinVerify;
    } else if (intent == 'changeQuestions') {
      _mode = _Mode.changeQuestionsOnly;
    } else if (intent == 'setup') {
      _mode = _Mode.setupQuestions;
    } else if (ctrl.isBiometricLockActive()) {
      _mode = _Mode.biometricOnly;
      _initBiometricOnly();
    } else {
      _mode = hasPin ? _Mode.verify : _Mode.setupQuestions;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ── Biometrics ────────────────────────────────────────────────────────────
  Future<void> _initBiometricOnly() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (!mounted) return;
      if (canCheck && isSupported) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) _triggerBiometric();
        });
      }
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
      if (ok && mounted) {
        Get.find<NoteController>().setSessionUnlocked(true);
        Get.offAllNamed(AppRoute.HOME);
      }
    } catch (_) {
      // dialog dismissed or unavailable — user can tap the button to retry
    }
  }

  // ── PIN verify (unlock / change-PIN gate) ─────────────────────────────────
  void _verifyPin(String pin) {
    final ok = Get.find<NoteController>().verifyPassword(pin);
    if (ok) {
      if (_mode == _Mode.changePinVerify) {
        _pinController.clear();
        setState(() {
          _mode = _Mode.changePinCreate;
          _pinError = false;
        });
      } else {
        Get.find<NoteController>().setSessionUnlocked(true);
        Get.offAllNamed(AppRoute.HOME);
      }
    } else {
      _pinController.clear();
      setState(() => _pinError = true);
    }
  }

  // ── Two-step PIN creation (setup + change flows) ──────────────────────────
  void _onPinCreateCompleted(String pin) {
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
        Get.find<NoteController>().setPassword(pin);
        if (_fromSettings) {
          Get.back();
          Get.snackbar(
            'PIN updated',
            'Your new PIN has been saved',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 2),
          );
        } else {
          Get.offAllNamed(AppRoute.HOME);
        }
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

  // ── Security-question setup ───────────────────────────────────────────────
  void _submitAnswer() {
    _collectedAnswers.add(_answerController.text.trim().toLowerCase());
    _answerController.clear();
    if (_collectedAnswers.length == _questions.length) {
      Get.find<NoteController>().setSuggestions(_collectedAnswers);
    }
    setState(() {
      _questionIndex++;
      if (_questionIndex >= _questions.length) {
        if (_mode == _Mode.changeQuestionsOnly) {
          Get.back();
          Get.snackbar(
            'Questions updated',
            'Your security questions have been saved',
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 12,
            duration: const Duration(seconds: 2),
          );
        } else {
          _mode = _Mode.createPin;
        }
      }
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incorrect answer. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      _Mode.biometricOnly => _buildBiometricOnly(context),
      _Mode.setupQuestions ||
      _Mode.changeQuestionsOnly =>
        _buildSetupQuestions(context),
      _Mode.createPin || _Mode.changePinCreate => _buildCreatePin(context),
      _Mode.forgotPin => _buildForgotPin(context),
      _Mode.changePinVerify => _buildChangePinVerify(context),
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN: Verify PIN (app unlock)
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
                _pinErrorWidget(context, 'Incorrect PIN. Try again.'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN: Biometric-only unlock (no PIN fallback)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBiometricOnly(BuildContext context) {
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
                _lockIcon(theme, Icons.fingerprint_rounded),
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
                  'Verify your identity to continue',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                OutlinedButton.icon(
                  onPressed: _triggerBiometric,
                  icon: const Icon(Icons.fingerprint_rounded, size: 22),
                  label: const Text('Use Fingerprint'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    side: BorderSide(color: theme.dividerColor),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN: Verify current PIN (before changing it)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildChangePinVerify(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _settingsAppBar(context, 'Change PIN'),
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
                  'Verify your PIN',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your current PIN to continue',
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
                _pinErrorWidget(context, 'Incorrect PIN. Try again.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SCREEN: Security-question setup (step 1–3) — shared by setup & change
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSetupQuestions(BuildContext context) {
    final theme = Theme.of(context);
    final isChangeMode = _mode == _Mode.changeQuestionsOnly;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isChangeMode
          ? _settingsAppBar(context, 'Security Questions')
          : null,
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
                isChangeMode ? 'Update Security Questions' : 'Security Setup',
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
                    _questionIndex < _questions.length - 1
                        ? 'Next'
                        : 'Save Questions',
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
  // SCREEN: Create / Change PIN — with two-step confirmation
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCreatePin(BuildContext context) {
    final theme = Theme.of(context);
    final isChangeMode = _mode == _Mode.changePinCreate;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: isChangeMode
          ? _settingsAppBar(
              context,
              'Change PIN',
              onBack: _confirmingNewPin
                  ? () => setState(() {
                        _confirmingNewPin = false;
                        _newPinBuffer = null;
                        _pinController.clear();
                        _pinError = false;
                      })
                  : null,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _lockIcon(
                  theme,
                  _confirmingNewPin
                      ? Icons.lock_reset_rounded
                      : Icons.lock_open_rounded,
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(_confirmingNewPin),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _confirmingNewPin
                            ? 'Confirm your PIN'
                            : isChangeMode
                                ? 'Create new PIN'
                                : 'Create your PIN',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _confirmingNewPin
                            ? 'Re-enter your PIN to confirm'
                            : 'Choose a 4-digit PIN to protect your notes',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _pinField(
                  context,
                  controller: _pinController,
                  hasError: _pinError,
                  onChanged: (_) {
                    if (_pinError) setState(() => _pinError = false);
                  },
                  onCompleted: _onPinCreateCompleted,
                ),
                _pinErrorWidget(
                  context,
                  _confirmingNewPin
                      ? 'PINs do not match. Try again.'
                      : 'Something went wrong. Try again.',
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
  AppBar _settingsAppBar(
    BuildContext context,
    String title, {
    VoidCallback? onBack,
  }) {
    final theme = Theme.of(context);
    return AppBar(
      leading: BackButton(onPressed: onBack ?? () => Navigator.of(context).pop()),
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _pinErrorWidget(BuildContext context, String message) {
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _pinError
          ? Padding(
              key: const ValueKey('err'),
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            )
          : const SizedBox(key: ValueKey('no-err'), height: 12),
    );
  }

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
        activeColor:
            hasError ? theme.colorScheme.error : theme.colorScheme.onSurface,
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

