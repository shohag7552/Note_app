import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_note_app/controller/note_controller.dart';
import 'package:my_note_app/routing/app_routes.dart';
import 'package:my_note_app/services/sync_service.dart';

/// Shown immediately after Google Sign-In completes.
/// Observes [SyncService.syncStatus] and auto-navigates to
/// [HomePage] when sync is done.
class SyncProgressScreen extends StatefulWidget {
  const SyncProgressScreen({super.key});

  @override
  State<SyncProgressScreen> createState() => _SyncProgressScreenState();
}

class _SyncProgressScreenState extends State<SyncProgressScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Safety valve: if sync takes > 12s, navigate anyway.
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && !_done) _navigateHome();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _navigateHome() {
    if (_done) return;
    _done = true;
    Get.find<NoteController>().getAllNotes();
    Get.offAllNamed(AppRoute.HOME);
  }

  String _statusMessage(String status) {
    switch (status) {
      case 'syncing':
        return 'Syncing your notes…';
      case 'done':
        return 'All caught up! ✓';
      case 'error':
        return 'Sync completed with warnings';
      default:
        return 'Setting up your account…';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GetBuilder<SyncService>(
        builder: (sync) {
          final isDone =
              sync.syncStatus == 'done' || sync.syncStatus == 'error';

          // Auto-navigate after a short celebration delay
          if (isDone && !_done) {
            Future.delayed(const Duration(milliseconds: 900), () {
              if (mounted) _navigateHome();
            });
          }

          return SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top progress bar
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: isDone
                          ? const SizedBox(
                              key: ValueKey('done-bar'),
                              height: 3,
                            )
                          : LinearProgressIndicator(
                              key: const ValueKey('progress-bar'),
                              backgroundColor:
                                  theme.colorScheme.outline.withValues(alpha: 0.3),
                              color: theme.colorScheme.primary,
                              minHeight: 3,
                            ),
                    ),

                    const Spacer(flex: 2),

                    // Animated icon
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) {
                        final pulse =
                            isDone ? 1.0 : 0.85 + _pulseCtrl.value * 0.15;
                        return Transform.scale(
                          scale: pulse,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                                  : theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: isDone
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      key: const ValueKey('check'),
                                      size: 48,
                                      color: const Color(0xFF22C55E),
                                    )
                                  : _RotatingCloudIcon(
                                      key: const ValueKey('cloud'),
                                      color: theme.colorScheme.primary,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Status text
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _statusMessage(sync.syncStatus),
                        key: ValueKey(sync.syncStatus),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Your notes are being backed up securely.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Skip button
                    if (!isDone)
                      TextButton(
                        onPressed: _navigateHome,
                        style: TextButton.styleFrom(
                          foregroundColor: theme.hintColor,
                        ),
                        child: const Text('Open app'),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Rotating cloud icon ──────────────────────────────────────────────────────

class _RotatingCloudIcon extends StatefulWidget {
  final Color color;
  const _RotatingCloudIcon({super.key, required this.color});

  @override
  State<_RotatingCloudIcon> createState() => _RotatingCloudIconState();
}

class _RotatingCloudIconState extends State<_RotatingCloudIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => RotationTransition(
        turns: _ctrl,
        child: child,
      ),
      child: Icon(Icons.sync_rounded, size: 48, color: widget.color),
    );
  }
}
