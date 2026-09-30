import 'clock.dart';
import 'focus_session.dart';

/// How many minutes the user wants to focus per day.
class DailyGoal {
  const DailyGoal([this.minutes = 120]);

  /// A goal within the allowed range of [minMinutes]–[maxMinutes].
  factory DailyGoal.validated(int minutes) {
    if (minutes < minMinutes || minutes > maxMinutes) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'must be $minMinutes–$maxMinutes',
      );
    }
    return DailyGoal(minutes);
  }

  static const minMinutes = 10;
  static const maxMinutes = 720;

  final int minutes;

  Duration get duration => Duration(minutes: minutes);

  /// The goal 10 minutes higher or lower, within the limits.
  DailyGoal step({required bool up}) =>
      DailyGoal((minutes + (up ? 10 : -10)).clamp(minMinutes, maxMinutes));

  @override
  bool operator ==(Object other) =>
      other is DailyGoal && other.minutes == minutes;

  @override
  int get hashCode => minutes.hashCode;
}

/// Focus time of all sessions that ended on the calendar day of [day]
/// (completed and cancelled; running sessions don't count yet).
Duration focusedOn(DateTime day, List<FocusSession> sessions) {
  final wanted = dayOf(day);
  var total = Duration.zero;
  for (final session in sessions) {
    final end = session.end;
    if (end != null && session.isFinished && dayOf(end) == wanted) {
      total += session.focusedTime(end);
    }
  }
  return total;
}

/// Share of [goal] reached with [focused], from 0 to 1.
double goalProgress(Duration focused, DailyGoal goal) =>
    (focused.inSeconds / goal.duration.inSeconds).clamp(0.0, 1.0);
