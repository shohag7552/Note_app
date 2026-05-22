import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:my_note_app/widgets/signout_dialog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'My Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: GetBuilder<AuthController>(
        builder: (auth) {
          final user = auth.getUser();
          final noteCount = Get.find<NoteController>().notes.length;
          final syncStatus = Get.find<SyncService>().syncStatus;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Profile Photo Header ──────────────────────────────────────────
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (user?.imageUrl ?? '').isNotEmpty
                              ? Image.network(
                                  user!.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _avatarFallback(theme),
                                )
                              : _avatarFallback(theme),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified_user_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Display Name & Email ──────────────────────────────────────────
                Text(
                  (user?.name ?? '').isNotEmpty ? user!.name : 'Notes App User',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? 'offline_user@notes.app',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),

                // ── Info Cards Section ────────────────────────────────────────────
                Text(
                  'Account Settings',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Account Stats Card
                _infoCard(
                  theme,
                  children: [
                    _infoRow(
                      theme,
                      icon: Icons.edit_note_rounded,
                      label: 'Total Notes',
                      trailing: Text(
                        '$noteCount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Divider(color: theme.dividerColor, height: 20),
                    _infoRow(
                      theme,
                      icon: Icons.sync_rounded,
                      label: 'Sync Status',
                      trailing: _syncChip(theme, syncStatus),
                    ),
                    Divider(color: theme.dividerColor, height: 20),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                      leading: Icon(
                        Icons.logout_rounded,
                        color: Colors.orange,
                      ),
                      title: Text(
                        'Sign out',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          // color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Colors.orange,
                      ),
                      onTap: () => SignOutDialog.show(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  'Danger Zone',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.error,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Danger zone card
                _infoCard(
                  theme,
                  borderColor: theme.colorScheme.error.withValues(alpha: 0.2),
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.delete_forever_rounded,
                        color: theme.colorScheme.error,
                      ),
                      title: Text(
                        'Delete Account',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Delete your account and erase all local and cloud note copies.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                          height: 1.3,
                        ),
                      ),
                      onTap: () => _showDeleteDialog(context, auth),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _avatarFallback(ThemeData theme) => Container(
        color: theme.cardColor,
        child: Icon(Icons.person_rounded, size: 60, color: theme.hintColor),
      );

  Widget _infoCard(ThemeData theme, {required List<Widget> children, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? theme.colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _infoRow(ThemeData theme, {required IconData icon, required String label, required Widget trailing}) {
    return Row(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
        const SizedBox(width: 14),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }

  Widget _syncChip(ThemeData theme, String status) {
    final isSynced = status == 'done';
    final isSyncing = status == 'syncing';
    final color = isSynced
        ? const Color(0xFF22C55E)
        : isSyncing
            ? theme.colorScheme.primary
            : theme.hintColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isSyncing ? 'Syncing' : isSynced ? 'Synced' : 'Offline',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AuthController auth) {
    final theme = Theme.of(context);
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            const Text('Delete Account?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
          'All your synchronized cloud notes will be permanently erased. '
          'You will be signed out, and you will not be able to log '
          'back into this account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          GetBuilder<AuthController>(
            builder: (authController) {
              return TextButton(
                onPressed: authController.isLoading
                    ? null
                    : () async {
                        final success = await authController.deactivateAccount();
                        if (!success) {
                          Get.back();
                          Get.snackbar(
                            'Error',
                            'Failed to delete account. Please try again.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: theme.colorScheme.error.withValues(alpha: 0.9),
                            colorText: Colors.white,
                          );
                        }
                      },
                child: authController.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Delete',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
