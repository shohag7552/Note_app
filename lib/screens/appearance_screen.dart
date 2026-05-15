import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        centerTitle: true,
      ),
      body: GetBuilder<NoteController>(
        builder: (ctrl) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            physics: const BouncingScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Grid Layout',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _layoutOption(
                ctrl,
                index: 0,
                icon: Icons.dashboard_outlined,
                label: 'Masonry Grid',
                description: 'Staggered dual-column layout',
              ),
              _layoutOption(
                ctrl,
                index: 1,
                icon: Icons.view_agenda_outlined,
                label: 'List View',
                description: 'Single-column full-width list',
              ),
              _layoutOption(
                ctrl,
                index: 2,
                icon: Icons.grid_view_outlined,
                label: 'Dense Grid',
                description: 'Compact 3-column layout',
              ),
              _layoutOption(
                ctrl,
                index: 3,
                icon: Icons.auto_awesome_mosaic_outlined,
                label: 'Quilted Grid',
                description: 'Fixed-height woven pattern',
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Card Design',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _designOption(
                ctrl,
                index: 0,
                label: 'Classic',
                description: 'The original side-stripe accent design',
              ),
              _designOption(
                ctrl,
                index: 1,
                label: 'Tinted Pastel',
                description: 'Soft translucent pastel backgrounds',
              ),
              _designOption(
                ctrl,
                index: 2,
                label: 'Minimalist',
                description: 'Clean outlined borders with flat surface',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _layoutOption(
    NoteController ctrl, {
    required int index,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final theme = Theme.of(Get.context!);
    final isSelected = ctrl.layoutIndex == index;
    final color =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.cardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          height: 1.4,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: () => ctrl.changeLayout(index),
    );
  }

  Widget _designOption(
    NoteController ctrl, {
    required int index,
    required String label,
    required String description,
  }) {
    final theme = Theme.of(Get.context!);
    final isSelected = ctrl.cardDesignIndex == index;
    final color =
        isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.cardColor,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.style_outlined, color: color, size: 22),
      ),
      title: Text(
        label,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: color,
        ),
      ),
      subtitle: Text(
        description,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.hintColor,
          height: 1.4,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
          : null,
      onTap: () => ctrl.changeCardDesign(index),
    );
  }
}
