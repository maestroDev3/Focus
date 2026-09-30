import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/clock.dart';
import '../domain/focus_session.dart';
import '../domain/statistics.dart';
import '../l10n/app_localizations.dart';
import 'focus_time_text.dart';

/// Honest, calm statistics derived from the stored sessions.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({
    super.key,
    required this.finishedSessions,
    required this.clock,
  });

  final Stream<List<FocusSession>> finishedSessions;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: StreamBuilder<List<FocusSession>>(
        stream: finishedSessions,
        builder: (context, snapshot) {
          final sessions = snapshot.data ?? const <FocusSession>[];
          final now = clock();
          final week = weekFocus(sessions, today: now);
          final today = week[now.weekday - DateTime.monday];
          final weekTotal = week.fold(Duration.zero, (sum, day) => sum + day);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      title: l10n.today,
                      value: focusTimeText(l10n, today),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      title: l10n.thisWeek,
                      value: focusTimeText(l10n, weekTotal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _WeekBars(
                week: week,
                monday: weekStart(now),
                todayIndex: now.weekday - DateTime.monday,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A calm card with a small title and a large value.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}

/// One thin bar per weekday, today in the accent color.
class _WeekBars extends StatelessWidget {
  const _WeekBars({
    required this.week,
    required this.monday,
    required this.todayIndex,
  });

  static const _maxBarHeight = 140.0;

  final List<Duration> week;
  final DateTime monday;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final longest = week.fold(
      Duration.zero,
      (max, day) => day > max ? day : max,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < week.length; index++)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      key: ValueKey('week-bar-$index'),
                      width: 14,
                      height: longest == Duration.zero
                          ? 2
                          : 2 +
                                _maxBarHeight *
                                    week[index].inSeconds /
                                    longest.inSeconds,
                      decoration: BoxDecoration(
                        color: index == todayIndex
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat.E(locale).format(
                        // Label from the local calendar date of that weekday.
                        DateTime(monday.year, monday.month, monday.day + index),
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: index == todayIndex
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
