import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/blocking.dart';
import '../l10n/app_localizations.dart';
import 'widgets/focus_background.dart';

/// Shown before a paused app opens outside sessions and focus times: a
/// breathing ring, how often the app was opened today, and the choice to go
/// back at once or to open the app after `mindfulPause`.
class BreathScreen extends StatefulWidget {
  const BreathScreen({
    super.key,
    required this.appLabel,
    required this.openedToday,
    required this.onOpen,
    required this.onGoBack,
  });

  final String appLabel;

  /// How often the app was opened today, this time included.
  final int openedToday;
  final VoidCallback onOpen;
  final VoidCallback onGoBack;

  @override
  State<BreathScreen> createState() => _BreathScreenState();
}

class _BreathScreenState extends State<BreathScreen>
    with SingleTickerProviderStateMixin {
  /// One calm breath: in for four seconds, out for four.
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  var _secondsLeft = mindfulPause.inSeconds;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final canOpen = _secondsLeft <= 0;

    return FocusBackground(
      glowCenter: const Alignment(0, -0.2),
      glowRadius: 0.8,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: Tween(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _breath,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.takeABreath,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.mindfulQuestion(widget.appLabel),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.mindfulOpenedToday(widget.openedToday),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: widget.onGoBack,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                  ),
                  child: Text(l10n.mindfulGoBack),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: canOpen ? widget.onOpen : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: Text(
                    canOpen
                        ? l10n.mindfulOpen(widget.appLabel)
                        : l10n.mindfulOpenIn(_secondsLeft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
