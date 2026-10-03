import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/countdown.dart';
import '../domain/focus_session.dart';
import '../domain/focus_timer.dart';
import '../l10n/app_localizations.dart';
import 'widgets/focus_background.dart';

/// Shows the running session: a calm countdown in a thin ring, pause/resume
/// and a deliberate way to end the session.
class SessionScreen extends StatefulWidget {
  const SessionScreen({
    super.key,
    required this.timer,
    required this.clock,
    required this.onDone,
    this.labelName,
    this.blockingActive,
    this.onTurnBlockingOn,
  });

  final FocusTimer timer;
  final Clock clock;

  /// Name of the session's label, shown in the heading.
  final String? labelName;

  /// False while apps are paused but app blocking is switched off; then the
  /// screen warns. Null when unknown (no warning).
  final ValueListenable<bool>? blockingActive;

  /// Opens the system settings to switch app blocking back on.
  final VoidCallback? onTurnBlockingOn;

  /// Called once with the outcome when the session was completed or ended.
  final ValueChanged<SessionOutcome> onDone;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  late final StreamSubscription<void> _ticks;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _ticks = Stream<void>.periodic(const Duration(seconds: 1)).listen(_tick);
  }

  @override
  void dispose() {
    _ticks.cancel();
    super.dispose();
  }

  Future<void> _tick(void _) async {
    final completed = await widget.timer.completeIfDue();
    if (!mounted) return;
    if (completed) {
      _finish(const SessionCompleted());
    } else {
      setState(() {});
    }
  }

  void _finish(SessionOutcome outcome) {
    if (_done) return;
    _done = true;
    _ticks.cancel();
    widget.onDone(outcome);
  }

  Future<void> _togglePause() async {
    final session = widget.timer.current;
    if (session == null) return;
    if (session.isPaused) {
      await widget.timer.resume();
    } else {
      await widget.timer.pause();
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _confirmEnd() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.endSessionTitle),
        content: Text(l10n.endSessionMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keepFocusing),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.endSession),
          ),
        ],
      ),
    );
    if (confirmed != true || widget.timer.current == null) return;
    await widget.timer.cancel();
    if (!mounted) return;
    _finish(const SessionCancelled());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = widget.timer.current;
    final now = widget.clock();
    final remaining = session?.remaining(now) ?? Duration.zero;
    final progress = switch (session) {
      final session? =>
        1 - remaining.inMilliseconds / session.planned.inMilliseconds,
      null => 1.0,
    };
    final paused = session?.isPaused ?? false;

    return PopScope(
      canPop: false,
      child: FocusBackground(
        glowCenter: const Alignment(0, -0.1),
        glowRadius: 0.8,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    switch ((paused, widget.labelName)) {
                      (true, _) => l10n.sessionPaused,
                      (false, final label?) => l10n.sessionFocusingWithLabel(label),
                      (false, null) => l10n.sessionFocusing,
                    },
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 3,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: _CountdownRing(
                        progress: progress,
                        countdown: formatCountdown(remaining),
                        caption: l10n.sessionRemaining,
                      ),
                    ),
                  ),
                  if (widget.blockingActive case final blockingActive?)
                    ValueListenableBuilder<bool>(
                      valueListenable: blockingActive,
                      builder: (context, active, _) => active
                          ? const SizedBox.shrink()
                          : _BlockingOffCard(onTurnOn: widget.onTurnBlockingOn),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _togglePause,
                          child: Text(paused ? l10n.resume : l10n.pause),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _confirmEnd,
                          child: Text(l10n.endSession),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Clear but calm warning that paused apps can be opened right now.
class _BlockingOffCard extends StatelessWidget {
  const _BlockingOffCard({required this.onTurnOn});

  final VoidCallback? onTurnOn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.blockingOffTitle,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l10n.blockingOffBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTurnOn,
                child: Text(l10n.turnBlockingBackOn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The remaining time in the display face inside a thin progress ring.
class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.progress,
    required this.countdown,
    required this.caption,
  });

  final double progress;
  final String countdown;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 1.5,
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.outline,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(countdown, style: theme.textTheme.displayLarge),
              const SizedBox(height: 4),
              Text(
                caption,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
