import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/clock.dart';
import '../domain/day_part.dart';
import '../l10n/app_localizations.dart';

/// The calm first screen: date, a greeting and one big button to start
/// focusing without any friction.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.clock,
    required this.focusDuration,
    required this.onStart,
    required this.onOpenSettings,
    required this.blockedAppCount,
    required this.onOpenBlockedApps,
    required this.blockerNeedsPermission,
    required this.onAllowBlocking,
  });

  final Clock clock;
  final Duration focusDuration;
  final VoidCallback onStart;
  final VoidCallback onOpenSettings;

  /// Number of apps paused during sessions.
  final int blockedAppCount;
  final VoidCallback onOpenBlockedApps;

  /// Apps are paused but the blocker is not allowed yet.
  final bool blockerNeedsPermission;
  final VoidCallback onAllowBlocking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = clock();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final greeting = switch (dayPartOf(now)) {
      DayPart.morning => l10n.greetingMorning,
      DayPart.afternoon => l10n.greetingAfternoon,
      DayPart.evening => l10n.greetingEvening,
    };

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat.MMMMEEEEd(locale).format(now),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onOpenSettings,
                    tooltip: l10n.settings,
                    color: theme.colorScheme.onSurfaceVariant,
                    icon: const Icon(Icons.tune),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(greeting, style: theme.textTheme.displaySmall),
              const SizedBox(height: 8),
              Text(
                l10n.homeSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Spacer(),
              _PlannedDuration(minutes: focusDuration.inMinutes),
              const SizedBox(height: 28),
              Center(
                child: ActionChip(
                  onPressed: onOpenBlockedApps,
                  avatar: Icon(
                    Icons.do_not_disturb_on_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(
                    blockedAppCount == 0
                        ? l10n.chooseAppsToPause
                        : l10n.appsPaused(blockedAppCount),
                  ),
                ),
              ),
              if (blockerNeedsPermission)
                Center(
                  child: TextButton.icon(
                    onPressed: onAllowBlocking,
                    icon: const Icon(Icons.warning_amber_outlined),
                    label: Text(l10n.allowAppBlocking),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: onStart,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(64),
                ),
                child: Text(l10n.beginFocus),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The planned session length inside a thin champagne ring.
class _PlannedDuration extends StatelessWidget {
  const _PlannedDuration({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        width: 236,
        height: 236,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        child: Text(
          AppLocalizations.of(context).durationMinutes(minutes),
          style: theme.textTheme.displayMedium,
        ),
      ),
    );
  }
}
