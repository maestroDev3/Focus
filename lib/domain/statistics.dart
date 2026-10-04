import 'clock.dart';
import 'focus_session.dart';

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
