import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';

/// Professional sign-out confirmation dialog.
class SignOutDialog extends StatelessWidget {
  const SignOutDialog({super.key});

  static Future<void> show() {
    return showDialog<void>(
      context: Get.context!,
      barrierDismissible: true,
      builder: (_) => const SignOutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();
    final email = auth.getUser()?.email ?? '';

    return Dialog(
      backgroundColor: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded,
                    color: theme.colorScheme.error, size: 26),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sign out?',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700, letterSpacing: -0.3),
            ),
            const SizedBox(height: 8),
            if (email.isNotEmpty) ...[
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(email,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Your notes are saved on this device and will remain safe.\n\nThey\'ll sync automatically when you sign back in.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.hintColor, height: 1.5),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.outline),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GetBuilder<AuthController>(
                    builder: (auth) => FilledButton(
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              await auth.googleLogOut();
                              Get.back();
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Sign out',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
