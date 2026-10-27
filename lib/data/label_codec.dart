import '../domain/focus_label.dart';

/// A label as JSON; the goal is stored in whole hours and only if set.
Map<String, Object?> encodeLabel(FocusLabel label) => {
  'id': label.id,
  'name': label.name,
  if (label.goal case final goal?) 'goalHours': goal.inHours,
  if (label.weeklyGoal case final weekly?) 'weeklyGoalHours': weekly.inHours,
};

/// The goal of a JSON label, null without `goalHours` (older data).
Duration? decodeLabelGoal(Object? json) => switch (json) {
  {'goalHours': final int hours} => Duration(hours: hours),
  {'goalHours': _} => throw FormatException('Malformed label goal: $json'),
  _ => null,
};

/// The weekly goal of a JSON label, null without `weeklyGoalHours`.
Duration? decodeLabelWeeklyGoal(Object? json) => switch (json) {
  {'weeklyGoalHours': final int hours} => Duration(hours: hours),
  {'weeklyGoalHours': _} => throw FormatException(
    'Malformed weekly label goal: $json',
  ),
  _ => null,
};
