import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/controller/background_controller.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/screens/setting_screen/font_style_screen.dart';

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
          builder: (noteController) {
            return GetBuilder<AuthController>(
              builder: (authController) {
                final loggedIn = authController.getUserToken() != null;
                final user = authController.getUser();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: loggedIn
                          ? Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: theme.dividerColor),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: (user?.imageUrl ?? '').isNotEmpty
                                      ? Image.network(
                                          user!.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _avatarFallback(theme),
                                        )
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
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user?.email ?? '',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.hintColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sign in to sync your notes to the cloud.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: () =>
                                        Get.find<AuthController>().googleLogin(),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.colorScheme.primary,
                                      foregroundColor: theme.colorScheme.onPrimary,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    icon: const Icon(Icons.login_rounded, size: 18),
                                    label: const Text(
                                      'Sign in with Google',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Divider(color: theme.dividerColor, height: 1),
                    const SizedBox(height: 8),
                    if (loggedIn) ...[
                      _row(
                        context,
                        icon: Icons.cloud_download_outlined,
                        label: 'Pull notes from cloud',
                        onTap: () =>
                            Get.find<BackgroundController>().getAllNotes(),
                      ),
                      _row(
                        context,
                        icon: Icons.cloud_upload_outlined,
                        label: 'Upload notes to cloud',
                        onTap: () =>
                            Get.find<BackgroundController>().uploadAllNotes(),
                      ),
                      Divider(color: theme.dividerColor, height: 16, indent: 16, endIndent: 16),
                    ],
                    _row(
                      context,
                      icon: Icons.font_download_outlined,
                      label: 'Change font style',
                      onTap: () {
                        Get.back();
                        Get.to(() => const FontStyleScreen());
                      },
                    ),
                    _row(
                      context,
                      icon: Icons.palette_outlined,
                      label: 'Appearance',
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoute.APPEARANCE);
                      },
                    ),
                    _row(
                      context,
                      icon: Icons.lock_outline_rounded,
                      label: 'App Lock',
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoute.appLock);
                      },
                    ),
                    _toggleRow(
                      context,
                      icon: noteController.darkTheme
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      label: 'Dark mode',
                      value: noteController.darkTheme,
                      onChanged: (_) => noteController.toggleTheme(),
                    ),
                    const Spacer(),
                    if (loggedIn)
                      _row(
                        context,
                        icon: Icons.logout_rounded,
                        label: 'Sign out',
                        onTap: () => Get.find<AuthController>().googleLogOut(),
                        destructive: true,
                      ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _avatarFallback(ThemeData theme) => Container(
        color: theme.cardColor,
        child: Icon(Icons.person_rounded, color: theme.hintColor),
      );

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final theme = Theme.of(context);
    final color = destructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, size: 20, color: color),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: theme.colorScheme.primary,
        onChanged: onChanged,
      ),
      onTap: () => onChanged(!value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: const VisualDensity(vertical: -1),
    );
  }

}

