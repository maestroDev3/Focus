import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/focus_time.dart';
import '../domain/focus_time_repository.dart';
import '../domain/focus_week.dart';
import '../l10n/app_localizations.dart';
import 'focus_time_label.dart';

/// The planned week as a calendar: every focus-time range at its day and
/// hours, so overlaps and free gaps become visible (#362).
class FocusWeekScreen extends StatelessWidget {
  const FocusWeekScreen({
    super.key,
    required this.focusTimes,
    this.onOpenFocusTime,
    this.clock = DateTime.now,
  });

  final FocusTimeRepository focusTimes;

  /// Decides today, the now line and the running range; read once per build,
  /// nothing animates (#363).
  final Clock clock;

  /// Called when an entry is tapped, with its focus time.
  final ValueChanged<FocusTime>? onOpenFocusTime;

  static const _hourHeight = 56.0;
  static const _gutterWidth = 44.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.weekCalendar)),
      body: StreamBuilder<List<FocusTime>>(
        stream: focusTimes.watchFocusTimes(),
        builder: (context, snapshot) {
          final times = snapshot.data ?? const <FocusTime>[];
          final week = FocusWeek.from(times);
          final now = FocusWeekNow.at(clock());
          if (week.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                l10n.weekEmpty,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          FocusTime? timeFor(FocusWeekEntry entry) => [
            for (final time in times)
              if (time.id == entry.focusTimeId) time,
          ].firstOrNull;
          final hours = week.lastHour - week.firstHour;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  children: [
                    const SizedBox(width: _gutterWidth),
                    for (var day = DateTime.monday;
                        day <= DateTime.sunday;
                        day++)
                      Expanded(
                        child: Text(
                          weekdayName(day, locale),
                          key: day == now.weekday
                              ? Key('week-today-$day')
                              : null,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: day == now.weekday
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: day == now.weekday
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: hours * _hourHeight + 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _gutterWidth,
                          child: Stack(
                            children: [
                              for (var hour = week.firstHour;
                                  hour < week.lastHour;
                                  hour++)
                                Positioned(
                                  top: (hour - week.firstHour) * _hourHeight,
                                  left: 0,
                                  right: 6,
                                  child: Text(
                                    minuteOfDayText(hour * 60, locale),
                                    textAlign: TextAlign.right,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        for (var day = DateTime.monday;
                            day <= DateTime.sunday;
                            day++)
                          Expanded(
                            child: _DayColumn(
                              weekday: day,
                              week: week,
                              now: now,
                              hourHeight: _hourHeight,
                              onOpen: onOpenFocusTime == null
                                  ? null
                                  : (entry) {
                                      final time = timeFor(entry);
                                      if (time != null) {
                                        onOpenFocusTime!(time);
                                      }
                                    },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One weekday as a stack: quiet hour lines behind the day's entries.
class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.weekday,
    required this.week,
    required this.now,
    required this.hourHeight,
    this.onOpen,
  });

  final int weekday;
  final FocusWeek week;
  final FocusWeekNow now;
  final double hourHeight;
  final ValueChanged<FocusWeekEntry>? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Stack(
          children: [
            for (var hour = week.firstHour; hour < week.lastHour; hour++)
              Positioned(
                top: (hour - week.firstHour) * hourHeight,
                left: 0,
                right: 0,
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
              ),
            for (final entry in week.entriesOn(weekday))
              Positioned(
                top:
                    (entry.startMinute - week.firstHour * 60) /
                    60 *
                    hourHeight,
                left: entry.column * width / entry.columns + 1,
                width: width / entry.columns - 2,
                height:
                    (entry.endMinute - entry.startMinute) / 60 * hourHeight,
                child: _WeekEntry(
                  key: Key(
                    'week-entry-$weekday-${entry.focusTimeId}-'
                    '${entry.startMinute}',
                  ),
                  entry: entry,
                  active: now.isActive(entry),
                  onOpen: onOpen,
                ),
              ),
            if (weekday == now.weekday &&
                now.minuteOfDay >= week.firstHour * 60 &&
                now.minuteOfDay <= week.lastHour * 60)
              Positioned(
                key: const Key('week-now-line'),
                top:
                    (now.minuteOfDay - week.firstHour * 60) / 60 * hourHeight,
                left: 0,
                right: 0,
                child: Container(
                  height: 1.6,
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One focus-time range as a calm champagne block naming its hours; the
/// running one glows a little stronger (#363).
class _WeekEntry extends StatelessWidget {
  const _WeekEntry({
    super.key,
    required this.entry,
    this.active = false,
    this.onOpen,
  });

  final FocusWeekEntry entry;
  final bool active;
  final ValueChanged<FocusWeekEntry>? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Material(
      color: theme.colorScheme.primary.withValues(alpha: active ? 0.38 : 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(
            alpha: active ? 1 : 0.6,
          ),
          width: active ? 1.2 : 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onOpen == null ? null : () => onOpen!(entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          child: Text(
            '${minuteOfDayText(entry.startMinute, locale)}\n'
            '${minuteOfDayText(entry.endMinute, locale)}',
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontSize: 10,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
