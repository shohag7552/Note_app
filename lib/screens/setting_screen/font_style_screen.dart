import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_note_app/controller/note_controller.dart';

// Each entry is either a section header {'type': 'header', 'label': '...'}
// or a font item {'type': 'font', 'name': '...'}
const List<Map<String, String>> kFontEntries = [
  {'type': 'header', 'label': 'Sans-serif'},
  {'type': 'font', 'name': 'Inter'},
  {'type': 'font', 'name': 'Roboto'},
  {'type': 'font', 'name': 'Poppins'},
  {'type': 'font', 'name': 'Lato'},
  {'type': 'font', 'name': 'Nunito'},
  {'type': 'font', 'name': 'Open Sans'},
  {'type': 'font', 'name': 'DM Sans'},
  {'type': 'font', 'name': 'Montserrat'},
  {'type': 'font', 'name': 'Raleway'},
  {'type': 'font', 'name': 'Oswald'},
  {'type': 'font', 'name': 'Ubuntu'},
  {'type': 'font', 'name': 'Josefin Sans'},
  {'type': 'font', 'name': 'Rubik'},
  {'type': 'font', 'name': 'Work Sans'},
  {'type': 'font', 'name': 'Manrope'},
  {'type': 'font', 'name': 'Quicksand'},
  {'type': 'font', 'name': 'Lexend'},
  {'type': 'font', 'name': 'Plus Jakarta Sans'},
  {'type': 'font', 'name': 'Outfit'},
  {'type': 'font', 'name': 'Space Grotesk'},
  {'type': 'font', 'name': 'Figtree'},
  {'type': 'font', 'name': 'Exo 2'},
  {'type': 'header', 'label': 'Serif'},
  {'type': 'font', 'name': 'Merriweather'},
  {'type': 'font', 'name': 'Playfair Display'},
  {'type': 'font', 'name': 'Noto Serif'},
  {'type': 'font', 'name': 'Lora'},
  {'type': 'font', 'name': 'EB Garamond'},
  {'type': 'font', 'name': 'Libre Baskerville'},
  {'type': 'font', 'name': 'Cormorant Garamond'},
  {'type': 'font', 'name': 'Crimson Pro'},
  {'type': 'font', 'name': 'Source Serif 4'},
  {'type': 'font', 'name': 'Bitter'},
  {'type': 'font', 'name': 'Vollkorn'},
  {'type': 'header', 'label': 'Monospace'},
  {'type': 'font', 'name': 'JetBrains Mono'},
  {'type': 'font', 'name': 'Fira Code'},
  {'type': 'font', 'name': 'Source Code Pro'},
  {'type': 'font', 'name': 'Space Mono'},
  {'type': 'font', 'name': 'Roboto Mono'},
  {'type': 'font', 'name': 'Inconsolata'},
];

class FontStyleScreen extends StatelessWidget {
  const FontStyleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          'Font style',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: GetBuilder<NoteController>(
        builder: (controller) {
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: kFontEntries.length,
            itemBuilder: (context, index) {
              final entry = kFontEntries[index];

              if (entry['type'] == 'header') {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
                  child: Text(
                    entry['label']!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.hintColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                );
              }

              final name = entry['name']!;
              final isSelected = controller.currentFont == name;
              final isLast = index == kFontEntries.length - 1 ||
                  kFontEntries[index + 1]['type'] == 'header';

              return Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    onTap: () => controller.changeFont(name),
                    title: Text(
                      name,
                      style: GoogleFonts.getFont(
                        name,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'The quick brown fox jumps over the lazy dog',
                        style: GoogleFonts.getFont(
                          name,
                          fontSize: 13,
                          color: theme.hintColor,
                          height: 1.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check_circle_rounded,
                            color: theme.colorScheme.onSurface, size: 22)
                        : Icon(Icons.circle_outlined,
                            color: theme.dividerColor, size: 22),
                  ),
                  if (!isLast)
                    Divider(
                      color: theme.dividerColor,
                      height: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
