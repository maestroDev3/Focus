/// A recurring focus time, e.g. Mon–Fri 09:00–12:00, in local time.
class FocusTime {
  FocusTime({
    required this.id,
    required Set<int> weekdays,
    required this.startMinute,
    required this.endMinute,
  }) : weekdays = Set.unmodifiable(weekdays) {
    if (weekdays.isEmpty || weekdays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError.value(weekdays, 'weekdays', 'must be 1–7, not empty');
    }
    if (startMinute < 0 || endMinute > minutesPerDay) {
      throw ArgumentError('A focus time must lie within one day.');
    }
    if (endMinute - startMinute < minLengthMinutes) {
      throw ArgumentError(
        'A focus time must last at least $minLengthMinutes minutes.',
      );
    }
  }

  static const minLengthMinutes = 15;
  static const minutesPerDay = 24 * 60;

  final String id;

  /// ISO weekdays: Monday = 1 … Sunday = 7 (as [DateTime.weekday]).
  final Set<int> weekdays;

  /// Minutes after local midnight.
  final int startMinute;
  final int endMinute;

  bool isActiveAt(DateTime now) {
    final minute = now.hour * 60 + now.minute;
    return weekdays.contains(now.weekday) &&
        minute >= startMinute &&
        minute < endMinute;
  }

  /// The end of this focus time on the day of [now].
  DateTime endOn(DateTime now) =>
      DateTime(now.year, now.month, now.day, endMinute ~/ 60, endMinute % 60);

  @override
  bool operator ==(Object other) =>
      other is FocusTime &&
      other.id == id &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  int get hashCode =>
      Object.hash(id, startMinute, endMinute, Object.hashAllUnordered(weekdays));
}

/// The focus time running at [now], if any.
FocusTime? activeFocusTime(List<FocusTime> times, DateTime now) => [
  for (final time in times)
    if (time.isActiveAt(now)) time,
].firstOrNull;

/// The start of the next focus time after [now] within the coming week.
DateTime? nextFocusTimeStart(List<FocusTime> times, DateTime now) {
  DateTime? next;
  for (var offset = 0; offset <= 7; offset++) {
    final day = DateTime(now.year, now.month, now.day + offset);
    for (final time in times) {
      if (!time.weekdays.contains(day.weekday)) continue;
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        time.startMinute ~/ 60,
        time.startMinute % 60,
      );
      if (start.isAfter(now) && (next == null || start.isBefore(next))) {
        next = start;
      }
    }
    if (next != null) return next;
  }
  return next;
}

/// Whether two focus times share a weekday and their times intersect.
bool overlaps(FocusTime a, FocusTime b) =>
    a.weekdays.intersection(b.weekdays).isNotEmpty &&
    a.startMinute < b.endMinute &&
    b.startMinute < a.endMinute;

/// Consecutive runs of [weekdays] as (first, last) pairs, e.g. Mon–Fri as
/// (1, 5), so they can be shown compactly.
List<(int, int)> weekdayRuns(Set<int> weekdays) {
  final days = weekdays.toList()..sort();
  final runs = <(int, int)>[];
  for (final day in days) {
    if (runs.isNotEmpty && runs.last.$2 == day - 1) {
      runs[runs.length - 1] = (runs.last.$1, day);
    } else {
      runs.add((day, day));
    }
  }
  return runs;
}
