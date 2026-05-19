import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/auth_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/widgets/google_logo_icon.dart';

/// Full-screen branded login / welcome screen.
///
/// Shown only to truly new users (no notes + not logged in).
/// Existing offline users skip directly to HomePage.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 32, end: 0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic),
    );
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Decorative background blobs ──────────────────────────────────
          Positioned(
            top: -size.width * 0.3,
            right: -size.width * 0.2,
            child: _Blob(
              size: size.width * 0.8,
              color: isDark
                  ? const Color(0xFF1E1E2E)
                  : const Color(0xFFEEF2FF),
            ),
          ),
          Positioned(
            bottom: -size.width * 0.2,
            left: -size.width * 0.15,
            child: _Blob(
              size: size.width * 0.6,
              color: isDark
                  ? const Color(0xFF1A2420)
                  : const Color(0xFFF0FDF4),
            ),
          ),

          // ── Floating note cards (decorative) ────────────────────────────
          ..._buildFloatingCards(theme, size),

          // ── Main content ─────────────────────────────────────────────────
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeCtrl,
              builder: (_, __) => Opacity(
                opacity: _fadeAnim.value,
                child: Transform.translate(
                  offset: Offset(0, _slideAnim.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),

                        // ── App icon ────────────────────────────────────
                        AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: child,
                          ),
                          child: Center(
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurface,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.shadowColor.withValues(alpha: 0.15),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 44,
                                color: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Headline ─────────────────────────────────────
                        Text(
                          'My Notes',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Capture ideas.\nSync everywhere.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.hintColor,
                            height: 1.5,
                          ),
                        ),

                        const Spacer(flex: 3),

                        // ── Google Sign-In button ────────────────────────
                        GetBuilder<AuthController>(
                          builder: (auth) => _GoogleSignInButton(
                            isLoading: auth.isLoading,
                            onTap: () async {
                              await auth.googleLogin();
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Continue offline ─────────────────────────────
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                Get.offAllNamed(AppRoute.HOME),
                            style: TextButton.styleFrom(
                              foregroundColor: theme.hintColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Continue without signing in',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: theme.hintColor,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Privacy note ─────────────────────────────────
                        Text(
                          'Notes are stored locally on your device.\nSign in to enable cloud backup & sync.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor.withValues(alpha: 0.6),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingCards(ThemeData theme, Size size) {
    final cards = [
      _FloatingCard(
        top: size.height * 0.18,
        left: -24,
        rotation: -0.18,
        label: '✨ Ideas',
        floatCtrl: _floatCtrl,
        phase: 0,
        theme: theme,
      ),
      _FloatingCard(
        top: size.height * 0.28,
        right: -16,
        rotation: 0.14,
        label: '📋 Tasks',
        floatCtrl: _floatCtrl,
        phase: 1,
        theme: theme,
      ),
      _FloatingCard(
        top: size.height * 0.42,
        left: 8,
        rotation: 0.08,
        label: '🎯 Goals',
        floatCtrl: _floatCtrl,
        phase: 2,
        theme: theme,
      ),
    ];
    return cards;
  }
}

// ─── Google Sign-In Button ───────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _GoogleSignInButton(
      {required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3A3A3A)
                : const Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onTap,
              splashColor: const Color(0xFF4285F4).withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: isLoading
                          ? SizedBox(
                              key: const ValueKey('spinner'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            )
                          : const GoogleLogoIcon(
                              key: ValueKey('glogo'), size: 22),
                    ),
                    const SizedBox(width: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        isLoading ? 'Signing in…' : 'Continue with Google',
                        key: ValueKey(isLoading),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          color: isDark
                              ? const Color(0xFFEDEDED)
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
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
}

// ─── Decorative helpers ──────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  final double top;
  final double? left;
  final double? right;
  final double rotation;
  final String label;
  final AnimationController floatCtrl;
  final int phase;
  final ThemeData theme;

  const _FloatingCard({
    required this.top,
    this.left,
    this.right,
    required this.rotation,
    required this.label,
    required this.floatCtrl,
    required this.phase,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: floatCtrl,
        builder: (_, child) {
          // Stagger each card's float phase
          final t = (floatCtrl.value + phase * 0.33) % 1.0;
          final offset = math.sin(t * math.pi * 2) * 8;
          return Transform.translate(
            offset: Offset(0, offset),
            child: child,
          );
        },
        child: Transform.rotate(
          angle: rotation,
          child: Opacity(
            opacity: 0.55,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outline),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
