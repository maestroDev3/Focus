import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/clock.dart';
import '../domain/daily_goal.dart';
import '../domain/day_part.dart';
import '../l10n/app_localizations.dart';
import 'widgets/focus_background.dart';
import 'focus_time_text.dart';

/// The calm first screen: date, a greeting and one big button to start
/// focusing without any friction.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.clock,
    required this.focusDuration,
    required this.onStart,
    required this.onOpenSettings,
    required this.labelName,
    required this.hasLabels,
    required this.onChooseLabel,
    required this.focusedToday,
    required this.dailyGoal,
    required this.onOpenStatistics,
  });

  final Clock clock;
  final Duration focusDuration;
  final VoidCallback onStart;
  final VoidCallback onOpenSettings;

  /// Label chosen for the next session, or null.
  final String? labelName;

  /// Whether any labels exist yet.
  final bool hasLabels;
  final VoidCallback onChooseLabel;

  /// Focus time of sessions that ended today.
  final Duration focusedToday;
  final DailyGoal dailyGoal;
  final VoidCallback onOpenStatistics;

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

    return FocusBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          // Scrolls instead of overflowing on small screens or large fonts;
          // on normal screens the spacers still center the content.
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
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
                              onPressed: onOpenStatistics,
                              tooltip: l10n.statistics,
                              color: theme.colorScheme.onSurfaceVariant,
                              icon: const Icon(Icons.insights_outlined),
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
                        _GoalRing(focused: focusedToday, goal: dailyGoal),
                        const SizedBox(height: 28),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            Chip(
                              avatar: Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(
                                l10n.durationMinutes(focusDuration.inMinutes),
                              ),
                            ),
                            ActionChip(
                              onPressed: onChooseLabel,
                              avatar: Icon(
                                Icons.label_outline,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(
                                labelName ??
                                    (hasLabels ? l10n.noLabel : l10n.addLabel),
                              ),
                            ),
                          ],
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's focus time inside a thin champagne ring that fills up towards the
/// daily goal.
class _GoalRing extends StatelessWidget {
  const _GoalRing({required this.focused, required this.goal});

  final Duration focused;
  final DailyGoal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: SizedBox.square(
        dimension: 236,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: goalProgress(focused, goal),
              strokeWidth: 2,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.outline,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.today,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  focusTimeText(l10n, focused),
                  style: theme.textTheme.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.dailyGoalOf(focusTimeText(l10n, goal.duration)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
