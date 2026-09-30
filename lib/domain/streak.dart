import 'clock.dart';
import 'daily_goal.dart';
import 'focus_session.dart';

/// Consecutive days with the daily goal reached, ending today – or ending
/// yesterday while today's goal is not reached yet, so the streak doesn't
/// break before the day is over.
int currentStreak(
  List<FocusSession> sessions,
  DailyGoal goal, {
  required DateTime today,
}) {
  final reached = _reachedDays(sessions, goal);
  var day = dayOf(today);
  if (!reached.contains(day)) day = day.subtract(_oneDay);
  var streak = 0;
  while (reached.contains(day)) {
    streak++;
    day = day.subtract(_oneDay);
  }
  return streak;
}

/// The longest run of consecutive days with the daily goal reached.
int bestStreak(List<FocusSession> sessions, DailyGoal goal) {
  final days = _reachedDays(sessions, goal).toList()..sort();
  var best = 0;
  var run = 0;
  DateTime? previous;
  for (final day in days) {
    final continues =
        previous != null && day.difference(previous) == _oneDay;
    run = continues ? run + 1 : 1;
    if (run > best) best = run;
    previous = day;
  }
  return best;
}

/// Days (normalized with [dayOf]) on which the goal was reached.
Set<DateTime> _reachedDays(List<FocusSession> sessions, DailyGoal goal) {
  final totals = <DateTime, Duration>{};
  for (final session in sessions) {
    final end = session.end;
    if (end == null || !session.isFinished) continue;
    final day = dayOf(end);
    totals[day] = (totals[day] ?? Duration.zero) + session.focusedTime(end);
  }
  return {
    for (final MapEntry(:key, :value) in totals.entries)
      if (value >= goal.duration) key,
  };
}

const _oneDay = Duration(days: 1);
