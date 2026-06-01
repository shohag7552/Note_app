import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/database_helper/database_helper.dart';
import 'package:my_note_app/model/note_model.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/screens/setting_screen/font_style_screen.dart';
import 'package:my_note_app/services/sync_service.dart';
import 'package:my_note_app/utils/app_constants.dart';
import 'package:my_note_app/widgets/google_logo_icon.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});
  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: GetBuilder<NoteController>(
          builder: (noteCtrl) => GetBuilder<AuthController>(
            builder: (authCtrl) {
              final loggedIn = authCtrl.isLoggedIn();
              final user = authCtrl.getUser();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────────────
                  loggedIn
                      ? _ProfileCard(user: user, theme: theme)
                      : _SignInCard(theme: theme),

                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 4),

                  // ── Sync row (logged-in only) ───────────────────────
                  if (loggedIn) _SyncRow(theme: theme),

                  if (loggedIn) Divider(
                      color: theme.dividerColor,
                      height: 16,
                      indent: 16,
                      endIndent: 16),

                  // ── Menu items ─────────────────────────────────────
                  _row(context,
                      icon: Icons.font_download_outlined,
                      label: 'Font style',
                      onTap: () {
                        Get.back();
                        Get.to(() => const FontStyleScreen());
                      }),
                  _row(context,
                      icon: Icons.palette_outlined,
                      label: 'Appearance',
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoute.APPEARANCE);
                      }),
                  _row(context,
                      icon: Icons.lock_outline_rounded,
                      label: 'App Lock',
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoute.appLock);
                      }),
                  _recycleBinRow(context, noteCtrl),
                  _toggleRow(
                    context,
                    icon: noteCtrl.darkTheme
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    label: 'Dark mode',
                    value: noteCtrl.darkTheme,
                    onChanged: (_) => noteCtrl.toggleTheme(),
                  ),

                  const Spacer(),
                  const SizedBox(height: 12),
                  Text(
                    'Version ${AppConstants.appVersion}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool destructive = false}) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, size: 20, color: color),
      title: Text(label,
          style: theme.textTheme.bodyMedium?.copyWith(
              color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  Widget _toggleRow(BuildContext context,
      {required IconData icon,
      required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    final theme = Theme.of(context);
    return ListTile(
      leading:
          Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      title: Text(label,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w500)),
      trailing: CupertinoSwitch(
          value: value,
          activeTrackColor: theme.colorScheme.primary,
          onChanged: onChanged),
      onTap: () => onChanged(!value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  Widget _recycleBinRow(BuildContext context, NoteController noteCtrl) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Note>>(
      future: DatabaseHelper.instance.getDeletedNotes(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return ListTile(
          leading: Icon(Icons.delete_outline_rounded,
              size: 20, color: theme.colorScheme.onSurface),
          title: Row(
            children: [
              Text('Recycle Bin',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Get.back();
            Get.toNamed(AppRoute.RECYCLE_BIN);
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          visualDensity: const VisualDensity(vertical: -1),
        );
      },
    );
  }
}

// ── Profile card (logged-in) ──────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final ThemeData theme;
  const _ProfileCard({required this.user, required this.theme});

  @override
  Widget build(BuildContext context) {
    final noteCount = Get.find<NoteController>().notes.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.back(); // close drawer
                Get.toNamed(AppRoute.PROFILE);
              },
              splashColor: theme.colorScheme.primary.withValues(alpha: 0.08),
              highlightColor: theme.colorScheme.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                width: 2),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (user?.imageUrl ?? '').isNotEmpty
                              ? Image.network(user!.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _avatarFallback(theme))
                              : _avatarFallback(theme),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (user?.name.isNotEmpty ?? false)
                                    ? user!.name
                                    : 'You',
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(user?.email ?? '',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: theme.hintColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: theme.hintColor, size: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                            label: '$noteCount ${noteCount == 1 ? 'note' : 'notes'}',
                            icon: Icons.edit_note_rounded,
                            theme: theme),
                        const SizedBox(width: 8),
                        GetBuilder<SyncService>(
                          builder: (sync) => _SyncStatusChip(
                              status: sync.syncStatus, theme: theme),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatarFallback(ThemeData theme) => Container(
        color: theme.cardColor,
        child: Icon(Icons.person_rounded, color: theme.hintColor),
      );
}

// ── Sign-in card (logged-out) ─────────────────────────────────────────────────

class _SignInCard extends StatelessWidget {
  final ThemeData theme;
  const _SignInCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.outline.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cloud_off_rounded,
                      size: 20, color: theme.hintColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Offline mode',
                          style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600)),
                      Text('Sign in to back up & sync',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GetBuilder<AuthController>(
              builder: (auth) => SizedBox(
                width: double.infinity,
                height: 44,
                child: _DrawerGoogleButton(
                    isLoading: auth.isLoading,
                    onTap: () {
                      Get.back();
                      auth.googleLogin();
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sync row ──────────────────────────────────────────────────────────────────

class _SyncRow extends StatelessWidget {
  final ThemeData theme;
  const _SyncRow({required this.theme});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SyncService>(
      builder: (sync) {
        final isSyncing = sync.isSyncing;
        final lastLabel = isSyncing ? 'Syncing…' : _lastSyncLabel(sync.syncStatus);
        return ListTile(
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isSyncing
                ? SizedBox(
                    key: const ValueKey('spin'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Icon(Icons.cloud_done_outlined,
                    key: const ValueKey('done'), size: 20),
          ),
          title: Text(lastLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor)),
          trailing: isSyncing
              ? null
              : TextButton(
                  onPressed: () => Get.find<AuthController>().syncNow(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Sync now',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          visualDensity: const VisualDensity(vertical: -3),
        );
      },
    );
  }

  String _lastSyncLabel(String status) {
    if (status == 'done') return 'Synced';
    if (status == 'error') return 'Sync had issues';
    return 'Not synced yet';
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final ThemeData theme;
  const _StatChip(
      {required this.label, required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.hintColor),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Sync status chip ──────────────────────────────────────────────────────────

class _SyncStatusChip extends StatelessWidget {
  final String status;
  final ThemeData theme;
  const _SyncStatusChip({required this.status, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isSynced = status == 'done';
    final isSyncing = status == 'syncing';
    final color = isSynced
        ? const Color(0xFF22C55E)
        : isSyncing
            ? theme.colorScheme.primary
            : theme.hintColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text(
            isSyncing ? 'Syncing' : isSynced ? 'Synced' : 'Offline',
            style: theme.textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Google button ──────────────────────────────────────────────────────

class _DrawerGoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _DrawerGoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        side: BorderSide(
            color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: theme.colorScheme.primary))
              : const GoogleLogoIcon(size: 18),
          const SizedBox(width: 10),
          Text(
            isLoading ? 'Signing in…' : 'Continue with Google',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFEDEDED) : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}
