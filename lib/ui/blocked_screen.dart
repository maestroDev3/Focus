import 'package:flutter/material.dart';

import '../domain/countdown.dart';
import '../l10n/app_localizations.dart';
import 'widgets/focus_background.dart';

/// Shown instead of a paused app while a session runs: a calm reminder and
/// the way back to the session.
class BlockedScreen extends StatelessWidget {
  const BlockedScreen({
    super.key,
    required this.appLabel,
    required this.remaining,
    required this.onReturn,
  });

  final String appLabel;

  /// Time left in the session, or null while it is paused.
  final Duration? remaining;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final remaining = this.remaining;

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
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.colorScheme.primary),
                        ),
                        child: Icon(
                          Icons.nightlight_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        appLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.blockedResting,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        remaining == null
                            ? l10n.blockedSessionPaused
                            : l10n.blockedRemaining(formatCountdown(remaining)),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onReturn,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(64),
                  ),
                  child: Text(l10n.returnToFocus),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
