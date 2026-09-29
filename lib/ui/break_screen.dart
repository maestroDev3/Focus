import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/break_session.dart';
import '../domain/clock.dart';
import '../domain/countdown.dart';
import '../domain/pomodoro.dart';
import '../l10n/app_localizations.dart';

/// Offers the break that follows a completed session and counts it down.
class BreakScreen extends StatefulWidget {
  const BreakScreen({
    super.key,
    required this.kind,
    required this.duration,
    required this.clock,
    required this.onDone,
  });

  final BreakKind kind;
  final Duration duration;
  final Clock clock;

  /// Called once when the break is over, ended or skipped.
  final VoidCallback onDone;

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen> {
  BreakSession? _break;
  StreamSubscription<void>? _ticks;
  var _done = false;

  @override
  void dispose() {
    _ticks?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _break = BreakSession(
        start: widget.clock(),
        kind: widget.kind,
        duration: widget.duration,
      );
    });
    _ticks = Stream<void>.periodic(const Duration(seconds: 1)).listen((_) {
      if (!mounted) return;
      final running = _break;
      if (running != null && running.isOver(widget.clock())) {
        _finish();
      } else {
        setState(() {});
      }
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _ticks?.cancel();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minutes = widget.duration.inMinutes;
    final title = switch (widget.kind) {
      BreakKind.short => l10n.breakShortTitle(minutes),
      BreakKind.long => l10n.breakLongTitle(minutes),
    };
    final running = _break;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  running == null ? l10n.breakWellDone : title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 3,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: running == null
                        ? Text(
                            title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.displaySmall,
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatCountdown(
                                  running.remaining(widget.clock()),
                                ),
                                style: theme.textTheme.displayLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.sessionRemaining,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                if (running == null) ...[
                  FilledButton(
                    onPressed: _start,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(64),
                    ),
                    child: Text(l10n.startBreak),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _finish,
                    child: Text(l10n.skipBreak),
                  ),
                ] else
                  OutlinedButton(
                    onPressed: _finish,
                    child: Text(l10n.endBreak),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
