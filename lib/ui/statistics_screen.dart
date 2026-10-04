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

/// Period of the whole statistics view.
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

  /// Index of the tapped day in the shown period; null = today.
  int? _selected;
  late final Stream<List<FocusSession>> _sessions = widget.finishedSessions;
  late final Stream<List<FocusLabel>> _labels = widget.labels;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
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
                // Local calendar dates for labels; sums come from the domain.
                final (firstDay, days, todayIndex) = switch (_period) {
                  StatisticsPeriod.week => (
                    DateTime(now.year, now.month, now.day - now.weekday + 1),
                    weekFocus(sessions, today: now),
                    now.weekday - DateTime.monday,
                  ),
                  StatisticsPeriod.month => (
                    DateTime(now.year, now.month),
                    monthFocus(sessions, today: now),
                    now.day - 1,
                  ),
                };
                final lastDay = DateTime(
                  firstDay.year,
                  firstDay.month,
                  firstDay.day + days.length - 1,
                );
                final byLabel = focusByLabel(
                  sessions,
                  from: firstDay,
                  to: lastDay,
                  labelIds: {for (final label in labels) label.id},
                );
                final total = days.fold(Duration.zero, (sum, day) => sum + day);
                final selected = _selected ?? todayIndex;
                final selectedDate = DateTime(
                  firstDay.year,
                  firstDay.month,
                  firstDay.day + selected,
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
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
                      onSelectionChanged: (selection) => setState(() {
                        _period = selection.first;
                        _selected = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            title: l10n.today,
                            value: focusTimeText(l10n, days[todayIndex]),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            title: switch (_period) {
                              StatisticsPeriod.week => l10n.thisWeek,
                              StatisticsPeriod.month => l10n.thisMonth,
                            },
                            value: focusTimeText(l10n, total),
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
                    _DayBars(
                      days: days,
                      firstDay: firstDay,
                      todayIndex: todayIndex,
                      selectedIndex: selected,
                      weekdayLabels: _period == StatisticsPeriod.week,
                      onSelect: (index) => setState(() => _selected = index),
                      summary: l10n.dayFocusOfGoal(
                        DateFormat.MMMEd(locale).format(selectedDate),
                        focusTimeText(l10n, days[selected]),
                        focusTimeText(l10n, widget.dailyGoal.duration),
                      ),
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

/// One thin bar per day of the period; tapping a bar selects the day and
/// the line below states its focus time against the daily goal.
class _DayBars extends StatelessWidget {
  const _DayBars({
    required this.days,
    required this.firstDay,
    required this.todayIndex,
    required this.selectedIndex,
    required this.weekdayLabels,
    required this.onSelect,
    required this.summary,
  });

  static const _maxBarHeight = 140.0;

  final List<Duration> days;
  final DateTime firstDay;
  final int todayIndex;
  final int selectedIndex;

  /// Weekday names under the bars (week); day numbers otherwise (month).
  final bool weekdayLabels;
  final ValueChanged<int> onSelect;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final longest = days.fold(
      Duration.zero,
      (max, day) => day > max ? day : max,
    );
    final barWidth = weekdayLabels ? 14.0 : 6.0;

    String labelOf(int index) {
      final date = DateTime(
        firstDay.year,
        firstDay.month,
        firstDay.day + index,
      );
      if (weekdayLabels) return DateFormat.E(locale).format(date);
      final day = date.day;
      return day == 1 || day % 5 == 0 ? '$day' : '';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 24, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0; index < days.length; index++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            key: ValueKey('day-bar-$index'),
                            width: barWidth,
                            height: longest == Duration.zero
                                ? 2
                                : 2 +
                                      _maxBarHeight *
                                          days[index].inSeconds /
                                          longest.inSeconds,
                            decoration: BoxDecoration(
                              color: index == selectedIndex
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                              borderRadius: BorderRadius.circular(barWidth / 2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            labelOf(index),
                            maxLines: 1,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: index == todayIndex
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              summary,
              textAlign: TextAlign.center,
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
