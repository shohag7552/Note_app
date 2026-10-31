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

  /// Shown when notes couldn't reach Drive. Signing out would lose them.
  static void _showUnsyncedWarning(AuthController auth) {
    Get.dialog(
      AlertDialog(
        title: const Text('Some notes aren\'t backed up'),
        content: const Text(
          'Some notes couldn\'t be uploaded to Google Drive. '
          'If you sign out now, they will be permanently deleted from this device.\n\n'
          'Check your connection and try again, or stay signed in to keep them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Stay signed in'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await auth.googleLogOut(force: true);
            },
            child: const Text('Sign out and delete'),
          ),
        ],
      ),
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
              'Your notes will be backed up to your Google Drive, then removed from this device.\n\nThey\'ll come back when you sign in again.',
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
                              final signedOut = await auth.googleLogOut();
                              Get.back();
                              if (!signedOut) _showUnsyncedWarning(auth);
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
