import '../domain/focus_label.dart';

/// A label as JSON; the goal is stored in whole hours and only if set.
Map<String, Object?> encodeLabel(FocusLabel label) => {
  'id': label.id,
  'name': label.name,
  if (label.goal case final goal?) 'goalHours': goal.inHours,
};

/// The goal of a JSON label, null without `goalHours` (older data).
Duration? decodeLabelGoal(Object? json) => switch (json) {
  {'goalHours': final int hours} => Duration(hours: hours),
  {'goalHours': _} => throw FormatException('Malformed label goal: $json'),
  _ => null,
};
