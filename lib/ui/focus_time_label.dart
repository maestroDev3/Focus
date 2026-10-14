import 'package:intl/intl.dart';

import '../domain/focus_time.dart';

/// Short localized weekday name, e.g. “Mon” for 1.
String weekdayName(int weekday, String locale) =>
    // 2026-09-28 is a Monday.
    DateFormat.E(locale).format(DateTime(2026, 9, 28 + weekday - 1));

/// Localized clock time for minutes of the day, e.g. “09:00”.
String minuteOfDayText(int minute, String locale) =>
    DateFormat.Hm(
      locale,
    ).format(DateTime(2026, 1, 1, minute ~/ 60, minute % 60));

/// “Mon–Fri · 09:00–12:00”, “Sat, Sun · 10:00–11:30”; several ranges are
/// joined without the inner dot: “Mon–Wed, Fri 07:00–10:00 · Sat
/// 07:00–12:00”.
String focusTimeLabel(FocusTime time, String locale) => [
  for (final range in time.ranges)
    focusTimeRangeLabel(
      range,
      locale,
      separator: time.ranges.length == 1 ? ' · ' : ' ',
    ),
].join(' · ');

/// “Mon–Fri · 09:00–12:00” for one range; [separator] goes between days
/// and hours.
String focusTimeRangeLabel(
  FocusTimeRange range,
  String locale, {
  String separator = ' · ',
}) {
  final days = [
    for (final (first, last) in weekdayRuns(range.weekdays))
      switch (last - first) {
        0 => weekdayName(first, locale),
        1 => '${weekdayName(first, locale)}, ${weekdayName(last, locale)}',
        _ => '${weekdayName(first, locale)}–${weekdayName(last, locale)}',
      },
  ].join(', ');
  final start = minuteOfDayText(range.startMinute, locale);
  final end = minuteOfDayText(range.endMinute, locale);
  return '$days$separator$start–$end';
}
