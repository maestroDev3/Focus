import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/clock.dart';
import '../domain/daily_goal.dart';
import '../domain/focus_label.dart';
import '../domain/focus_session.dart';
import '../domain/statistics.dart';
import '../domain/streak.dart';
import '../l10n/app_localizations.dart';
import 'focus_time_text.dart';

/// Period of the label breakdown.
enum StatisticsPeriod { week, month }

/// Honest, calm statistics derived from the stored sessions.
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    super.key,
    required this.finishedSessions,
    required this.labels,
    required this.dailyGoal,
    required this.clock,
  });

  final Stream<List<FocusSession>> finishedSessions;
  final Stream<List<FocusLabel>> labels;

  /// Goal a day must reach to count for the streak.
  final DailyGoal dailyGoal;
  final Clock clock;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  var _period = StatisticsPeriod.week;
  late final Stream<List<FocusSession>> _sessions = widget.finishedSessions;
  late final Stream<List<FocusLabel>> _labels = widget.labels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: StreamBuilder<List<FocusLabel>>(
        stream: _labels,
        builder: (context, labelSnapshot) =>
            StreamBuilder<List<FocusSession>>(
              stream: _sessions,
              builder: (context, snapshot) {
                final labels = labelSnapshot.data ?? const <FocusLabel>[];
                final sessions = snapshot.data ?? const <FocusSession>[];
                final now = widget.clock();
                final (from, to) = switch (_period) {
                  StatisticsPeriod.week => (
                    weekStart(now),
                    weekStart(now).add(const Duration(days: 6)),
                  ),
                  StatisticsPeriod.month => (
                    DateTime(now.year, now.month),
                    DateTime(now.year, now.month + 1, 0),
                  ),
                };
                final byLabel = focusByLabel(
                  sessions,
                  from: from,
                  to: to,
                  labelIds: {for (final label in labels) label.id},
                );
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
                    const SizedBox(height: 12),
                    _StreakCard(
                      current: currentStreak(
                        sessions,
                        widget.dailyGoal,
                        today: now,
                      ),
                      best: bestStreak(sessions, widget.dailyGoal),
                    ),
                    const SizedBox(height: 12),
                    _WeekBars(
                      week: week,
                      monday: weekStart(now),
                      todayIndex: now.weekday - DateTime.monday,
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<StatisticsPeriod>(
                      segments: [
                        ButtonSegment(
                          value: StatisticsPeriod.week,
                          label: Text(l10n.periodWeek),
                        ),
                        ButtonSegment(
                          value: StatisticsPeriod.month,
                          label: Text(l10n.periodMonth),
                        ),
                      ],
                      selected: {_period},
                      onSelectionChanged: (selection) =>
                          setState(() => _period = selection.first),
                    ),
                    const SizedBox(height: 12),
                    _LabelBreakdown(byLabel: byLabel, labels: labels),
                  ],
                );
              },
            ),
      ),
    );
  }
}

/// The streak, stated calmly – no badges, no celebration.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.current, required this.best});

  final int current;
  final int best;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.currentStreak(current),
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              l10n.bestStreak(best),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Focus time per label with a thin proportional bar.
class _LabelBreakdown extends StatelessWidget {
  const _LabelBreakdown({required this.byLabel, required this.labels});

  final List<LabelFocus> byLabel;
  final List<FocusLabel> labels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final total = byLabel.fold(
      Duration.zero,
      (sum, entry) => sum + entry.focused,
    );
    String nameOf(String? id) => [
      for (final label in labels)
        if (label.id == id) label.name,
    ].firstOrNull ?? l10n.unlabeled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.byLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            if (byLabel.isEmpty)
              Text(
                l10n.noFocusYet,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            for (final entry in byLabel) ...[
              Row(
                children: [
                  Expanded(child: Text(nameOf(entry.labelId))),
                  Text(focusTimeText(l10n, entry.focused)),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: entry.focused.inSeconds / total.inSeconds,
                minHeight: 3,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
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
