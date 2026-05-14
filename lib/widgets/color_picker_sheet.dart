import 'package:flutter/material.dart';
import 'package:my_note_app/helper/color_extension.dart';

const List<String> kNoteColorPalette = [
  '#FFA0A4A8', // Default gray
  '#FFEF9A9A', // Red
  '#FFFFF176', // Yellow
  '#FFA5D6A7', // Green
  '#FF90CAF9', // Blue
  '#FFCE93D8', // Purple
  '#FFFFCC80', // Orange
  '#FFF48FB1', // Pink
  '#FF80DEEA', // Teal
  '#FFBCAAA4', // Brown
  '#FFFFE082', // Amber
  '#FFB0BEC5', // Blue-gray
];

class ColorPickerSheet extends StatefulWidget {
  final String currentColor;
  final void Function(String hex) onSelected;

  const ColorPickerSheet({
    super.key,
    required this.currentColor,
    required this.onSelected,
  });

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card color',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: kNoteColorPalette.map((hex) {
                final color = hex.toColor() as Color;
                final isSelected = _selected == hex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = hex);
                    widget.onSelected(hex);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        width: isSelected ? 2.5 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 22,
                            color: theme.colorScheme.onSurface,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
