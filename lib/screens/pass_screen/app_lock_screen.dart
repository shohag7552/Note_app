import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _deviceSupportsBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final isSupported = await auth.isDeviceSupported();
      if (mounted) {
        setState(() => _deviceSupportsBiometrics = canCheck && isSupported);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'App Lock',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: GetBuilder<NoteController>(
        builder: (ctrl) {
          final lockActive = ctrl.isPasswordActive();
          final hasPin = ctrl.isContainPassword();
          final biometricEnabled = ctrl.isBiometricEnabled();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              _SectionLabel(text: 'Protection', theme: theme),
              const SizedBox(height: 8),
              _Card(
                theme: theme,
                children: [
                  _ToggleTile(
                    theme: theme,
                    icon: Icons.lock_outline_rounded,
                    title: 'App Lock',
                    subtitle: lockActive
                        ? 'Your notes are protected with a PIN'
                        : 'Lock the app with a 4-digit PIN',
                    value: lockActive,
                    onChanged: (enable) => _handleLockToggle(ctrl, enable, hasPin),
                  ),
                  if (lockActive && hasPin && _deviceSupportsBiometrics) ...[
                    Divider(height: 1, indent: 56, color: theme.dividerColor),
                    _ToggleTile(
                      theme: theme,
                      icon: Icons.fingerprint_rounded,
                      title: 'Biometric Unlock',
                      subtitle: biometricEnabled
                          ? 'Use fingerprint to unlock the app'
                          : 'Enable fingerprint unlock',
                      value: biometricEnabled,
                      onChanged: (enable) => ctrl.setBiometricEnabled(enable),
                    ),
                  ],
                ],
              ),
              if (!lockActive)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                  child: Text(
                    'When enabled, you\'ll need to enter a 4-digit PIN every time you open the app.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                      height: 1.5,
                    ),
                  ),
                ),
              if (lockActive && hasPin) ...[
                const SizedBox(height: 24),
                _SectionLabel(text: 'Security', theme: theme),
                const SizedBox(height: 8),
                _Card(
                  theme: theme,
                  children: [
                    _NavTile(
                      theme: theme,
                      icon: Icons.dialpad_rounded,
                      title: 'Change PIN',
                      subtitle: 'Update your 4-digit unlock code',
                      onTap: () => Get.toNamed(
                        AppRoute.pass,
                        arguments: {'intent': 'changePin'},
                      ),
                    ),
                    Divider(height: 1, indent: 56, color: theme.dividerColor),
                    _NavTile(
                      theme: theme,
                      icon: Icons.shield_outlined,
                      title: 'Security Questions',
                      subtitle: 'Update your PIN recovery answers',
                      onTap: () => Get.toNamed(
                        AppRoute.pass,
                        arguments: {'intent': 'changeQuestions'},
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _handleLockToggle(NoteController ctrl, bool enable, bool hasPin) {
    if (enable) {
      ctrl.activePassword(true);
      if (!hasPin) {
        Get.toNamed(AppRoute.pass, arguments: {'intent': 'setup'});
      }
    } else {
      ctrl.activePassword(false);
      // Also disable biometric when app lock is turned off
      ctrl.setBiometricEnabled(false);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared layout widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.theme});
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.hintColor,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.theme, required this.children});
  final ThemeData theme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: value
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: value
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CupertinoSwitch(
              value: value,
              activeTrackColor: theme.colorScheme.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.theme,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final ThemeData theme;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: theme.hintColor),
          ],
        ),
      ),
    );
  }
}
