/// One block of a focus time: weekdays plus start and end, e.g. Mon–Fri
/// 09:00–12:00, in local time.
class FocusTimeRange {
  FocusTimeRange({
    required Set<int> weekdays,
    required this.startMinute,
    required this.endMinute,
  }) : weekdays = Set.unmodifiable(weekdays) {
    if (weekdays.isEmpty || weekdays.any((day) => day < 1 || day > 7)) {
      throw ArgumentError.value(weekdays, 'weekdays', 'must be 1–7, not empty');
    }
    if (startMinute < 0 || endMinute > FocusTime.minutesPerDay) {
      throw ArgumentError('A focus time must lie within one day.');
    }
    if (endMinute - startMinute < FocusTime.minLengthMinutes) {
      throw ArgumentError(
        'A focus time must last at least ${FocusTime.minLengthMinutes} '
        'minutes.',
      );
    }
  }

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

  /// The end of this range on the day of [now].
  DateTime endOn(DateTime now) =>
      DateTime(now.year, now.month, now.day, endMinute ~/ 60, endMinute % 60);

  /// Whether both ranges share a weekday and their times intersect.
  bool overlaps(FocusTimeRange other) =>
      weekdays.intersection(other.weekdays).isNotEmpty &&
      startMinute < other.endMinute &&
      other.startMinute < endMinute;

  @override
  bool operator ==(Object other) =>
      other is FocusTimeRange &&
      other.startMinute == startMinute &&
      other.endMinute == endMinute &&
      other.weekdays.length == weekdays.length &&
      other.weekdays.containsAll(weekdays);

  @override
  int get hashCode =>
      Object.hash(startMinute, endMinute, Object.hashAllUnordered(weekdays));
}

/// A recurring focus time with one or more ranges (#247), e.g. Mon–Wed, Fri
/// 07:00–10:00 and Sat 07:00–12:00, blocking one list.
class FocusTime {
  /// A focus time with a single range.
  FocusTime({
    required String id,
    required Set<int> weekdays,
    required int startMinute,
    required int endMinute,
    String? blockListId,
  }) : this.withRanges(
         id: id,
         ranges: [
           FocusTimeRange(
             weekdays: weekdays,
             startMinute: startMinute,
             endMinute: endMinute,
           ),
         ],
         blockListId: blockListId,
       );

  /// Throws [ArgumentError] without ranges or if its ranges overlap.
  FocusTime.withRanges({
    required this.id,
    required List<FocusTimeRange> ranges,
    this.blockListId,
  }) : ranges = List.unmodifiable(ranges) {
    if (ranges.isEmpty) {
      throw ArgumentError.value(ranges, 'ranges', 'must not be empty');
    }
    for (var i = 0; i < ranges.length; i++) {
      for (var j = i + 1; j < ranges.length; j++) {
        if (ranges[i].overlaps(ranges[j])) {
          throw ArgumentError('The focus time overlaps itself.');
        }
      }
    }
  }

  static const minLengthMinutes = 15;
  static const minutesPerDay = 24 * 60;

  final String id;

  /// The named block list this focus time blocks; null = the default list.
  final String? blockListId;

  /// When the focus time runs; never empty, never overlapping.
  final List<FocusTimeRange> ranges;

  /// The range running at [now], if any.
  FocusTimeRange? activeRange(DateTime now) => [
    for (final range in ranges)
      if (range.isActiveAt(now)) range,
  ].firstOrNull;

  bool isActiveAt(DateTime now) => activeRange(now) != null;

  /// When the focus time ends: the end of the range running at [now], else
  /// of its first range.
  int endMinuteAt(DateTime now) =>
      (activeRange(now) ?? ranges.first).endMinute;

  @override
  bool operator ==(Object other) =>
      other is FocusTime &&
      other.id == id &&
      other.blockListId == blockListId &&
      other.ranges.length == ranges.length &&
      [
        for (var i = 0; i < ranges.length; i++) other.ranges[i] == ranges[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hash(id, blockListId, Object.hashAll(ranges));
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
    for (final range in [for (final time in times) ...time.ranges]) {
      if (!range.weekdays.contains(day.weekday)) continue;
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        range.startMinute ~/ 60,
        range.startMinute % 60,
      );
      if (start.isAfter(now) && (next == null || start.isBefore(next))) {
        next = start;
      }
    }
    if (next != null) return next;
  }
  return next;
}

/// Whether any range of [a] overlaps any range of [b].
bool overlaps(FocusTime a, FocusTime b) => a.ranges.any(
  (range) => b.ranges.any(range.overlaps),
);

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

/// Strict mode: a running focus time can't be edited or deleted, so its
/// block can't be lifted early.
bool canChangeFocusTime(FocusTime time, DateTime now) => !time.isActiveAt(now);
