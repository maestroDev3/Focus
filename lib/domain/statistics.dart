import 'clock.dart';
import 'focus_session.dart';
import 'focus_time.dart';

/// Focus time per calendar day from [from] to [to] (inclusive), derived
/// from the stored sessions; a session counts for the day it ended and days
/// without focus are zero.
Map<DateTime, Duration> focusByDay(
  List<FocusSession> sessions, {
  required DateTime from,
  required DateTime to,
}) {
  final first = dayOf(from);
  final last = dayOf(to);
  final days = <DateTime, Duration>{
    for (var day = first; !day.isAfter(last); day = day.add(_oneDay))
      day: Duration.zero,
  };
  for (final session in sessions) {
    final end = session.end;
    if (end == null || !session.isFinished) continue;
    final day = dayOf(end);
    final total = days[day];
    if (total != null) days[day] = total + session.focusedTime(end);
  }
  return days;
}

/// Monday of the week containing [today], as a normalized day.
DateTime weekStart(DateTime today) {
  final day = dayOf(today);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Focus time for Monday to Sunday of the week containing [today].
List<Duration> weekFocus(
  List<FocusSession> sessions, {
  required DateTime today,
}) {
  final monday = weekStart(today);
  return focusByDay(
    sessions,
    from: monday,
    to: monday.add(const Duration(days: 6)),
  ).values.toList();
}

/// Focus time for every day of the month containing [today], first day
/// first.
List<Duration> monthFocus(
  List<FocusSession> sessions, {
  required DateTime today,
}) => focusByDay(
  sessions,
  from: DateTime(today.year, today.month),
  to: DateTime(today.year, today.month + 1, 0),
).values.toList();

/// Focus time of one label (`labelId` null = unlabeled).
typedef LabelFocus = ({String? labelId, Duration focused});

/// Focus time per label for sessions that ended between [from] and [to]
/// (inclusive days), sorted by focus time. Sessions without a label or with
/// a label that no longer exists (not in [labelIds]) count as unlabeled.
List<LabelFocus> focusByLabel(
  List<FocusSession> sessions, {
  required DateTime from,
  required DateTime to,
  required Set<String> labelIds,
}) {
  final first = dayOf(from);
  final last = dayOf(to);
  final totals = <String?, Duration>{};
  for (final session in sessions) {
    final end = session.end;
    if (end == null || !session.isFinished) continue;
    final day = dayOf(end);
    if (day.isBefore(first) || day.isAfter(last)) continue;
    final labelId = labelIds.contains(session.labelId) ? session.labelId : null;
    totals[labelId] =
        (totals[labelId] ?? Duration.zero) + session.focusedTime(end);
  }
  return [
    for (final MapEntry(:key, :value) in totals.entries)
      (labelId: key, focused: value),
  ]..sort((a, b) => b.focused.compareTo(a.focused));
}

const _oneDay = Duration(days: 1);

/// All-time focus time of every label in [labelIds] (zero without sessions),
/// counting finished sessions only; sessions of deleted labels are ignored.
Map<String, Duration> labelTotals(
  List<FocusSession> sessions, {
  required Set<String> labelIds,
}) {
  final totals = {for (final id in labelIds) id: Duration.zero};
  for (final session in sessions) {
    final end = session.end;
    final labelId = session.labelId;
    if (end == null || !session.isFinished || labelId == null) continue;
    if (totals[labelId] case final total?) {
      totals[labelId] = total + session.focusedTime(end);
    }
  }
  return totals;
}

/// How long paused apps rested between [from] and [to] (until [now]): the
/// union of all session intervals – pauses included, blocking stays strict
/// while paused – and all focus time ranges on their weekdays, so overlaps
/// count once (#207). Running sessions count up to [now].
Duration protectedTime(
  List<FocusSession> sessions,
  List<FocusTime> focusTimes, {
  required DateTime from,
  required DateTime to,
  required DateTime now,
}) {
  final end = now.isBefore(to) ? now : to;
  return _unionLength([
    ..._sessionIntervals(sessions, now),
    ..._focusTimeIntervals(focusTimes, from, end),
  ], from, end);
}

/// How long one paused app rested in a period, and through what (#333).
typedef AppRest = ({
  String packageName,
  Duration total,
  Duration focusTimes,
  Duration sessions,
});

/// Per paused app: how long it rested between [from] and [to] (until
/// [now]) – during sessions if it is in [defaultApps], and during the focus
/// times that block it (their named list from [listApps], else
/// [defaultApps]) – split into the focus-time part and the extra session
/// time outside focus times. Sorted by total; apps that never rested are
/// left out.
List<AppRest> appRestTimes(
  List<FocusSession> sessions,
  List<FocusTime> focusTimes, {
  required Set<String> defaultApps,
  required Map<String, Set<String>> listApps,
  required DateTime from,
  required DateTime to,
  required DateTime now,
}) {
  final end = now.isBefore(to) ? now : to;
  Set<String> appsOf(FocusTime time) => switch (time.blockListId) {
    final id? => listApps[id] ?? defaultApps,
    null => defaultApps,
  };
  final apps = {
    ...defaultApps,
    for (final time in focusTimes) ...appsOf(time),
  };
  final sessionIntervals = _sessionIntervals(sessions, now);
  final rests = <AppRest>[];
  for (final app in apps) {
    final focusIntervals = _focusTimeIntervals([
      for (final time in focusTimes)
        if (appsOf(time).contains(app)) time,
    ], from, end);
    final inFocusTimes = _unionLength(focusIntervals, from, end);
    final total = _unionLength([
      if (defaultApps.contains(app)) ...sessionIntervals,
      ...focusIntervals,
    ], from, end);
    if (total == Duration.zero) continue;
    rests.add((
      packageName: app,
      total: total,
      focusTimes: inFocusTimes,
      sessions: total - inFocusTimes,
    ));
  }
  return rests..sort(
    (a, b) => b.total != a.total
        ? b.total.compareTo(a.total)
        : a.packageName.compareTo(b.packageName),
  );
}

/// Sessions as intervals; running ones last until [now].
List<(DateTime, DateTime)> _sessionIntervals(
  List<FocusSession> sessions,
  DateTime now,
) => [for (final session in sessions) (session.start, session.end ?? now)];

/// The ranges of [focusTimes] on their weekdays from [from] until [end].
List<(DateTime, DateTime)> _focusTimeIntervals(
  List<FocusTime> focusTimes,
  DateTime from,
  DateTime end,
) => [
  for (
    var day = DateTime(from.year, from.month, from.day);
    day.isBefore(end);
    day = DateTime(day.year, day.month, day.day + 1)
  )
    for (final time in focusTimes)
      for (final range in time.ranges)
        if (range.weekdays.contains(day.weekday))
          (
            DateTime(day.year, day.month, day.day, 0, range.startMinute),
            DateTime(day.year, day.month, day.day, 0, range.endMinute),
          ),
];

/// Length of the union of [intervals], clipped to [from]–[end].
Duration _unionLength(
  List<(DateTime, DateTime)> intervals,
  DateTime from,
  DateTime end,
) {
  if (!end.isAfter(from)) return Duration.zero;
  final clipped = [
    for (final (start, stop) in intervals)
      if (stop.isAfter(from) && start.isBefore(end))
        (start.isBefore(from) ? from : start, stop.isAfter(end) ? end : stop),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  var total = Duration.zero;
  DateTime? openStart;
  DateTime? openEnd;
  for (final (start, stop) in clipped) {
    if (openStart == null || openEnd == null || start.isAfter(openEnd)) {
      if (openStart != null && openEnd != null) {
        total += openEnd.difference(openStart);
      }
      openStart = start;
      openEnd = stop;
    } else if (stop.isAfter(openEnd)) {
      openEnd = stop;
    }
  }
  if (openStart != null && openEnd != null) {
    total += openEnd.difference(openStart);
  }
  return total;
}

/// On how many days from [from] to [today] (both local calendar days) at
/// least one session ended – and how many days that period has so far.
({int focused, int days}) focusDays(
  List<FocusSession> sessions, {
  required DateTime from,
  required DateTime today,
}) {
  final first = DateTime(from.year, from.month, from.day);
  final last = DateTime(today.year, today.month, today.day);
  final focused = <DateTime>{
    for (final session in sessions)
      if (session.end case final end? when session.isFinished)
        if (DateTime(end.year, end.month, end.day) case final day
            when !day.isBefore(first) && !day.isAfter(last))
          day,
  };
  final days = DateTime.utc(last.year, last.month, last.day)
          .difference(DateTime.utc(first.year, first.month, first.day))
          .inDays +
      1;
  return (focused: focused.length, days: days);
}
