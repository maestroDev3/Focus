import 'focus_time.dart';

/// One focus-time range on one weekday, laid out for a calendar column:
/// slot [column] of [columns] side-by-side slots, so overlapping entries
/// stay readable next to each other (#362).
class FocusWeekEntry {
  const FocusWeekEntry({
    required this.weekday,
    required this.focusTimeId,
    required this.blockListId,
    required this.startMinute,
    required this.endMinute,
    required this.column,
    required this.columns,
  });

  /// ISO weekday this entry belongs to: Monday = 1 … Sunday = 7.
  final int weekday;

  final String focusTimeId;

  /// The named block list the focus time blocks; null = the default list.
  final String? blockListId;

  /// Minutes after local midnight, like [FocusTimeRange].
  final int startMinute;
  final int endMinute;

  /// Horizontal slot within an overlap cluster, 0-based.
  final int column;

  /// Side-by-side slots of the cluster; 1 where nothing overlaps.
  final int columns;
}

/// The planned week: focus times repeat weekly, so one Mon–Sun grid shows
/// everything there is to plan. Pure data for the calendar screen – entries
/// per ISO weekday, already sorted and laid out in columns.
class FocusWeek {
  FocusWeek._(this._days, this.firstHour, this.lastHour);

  /// Expands every range of every focus time into its weekday entries.
  factory FocusWeek.from(List<FocusTime> focusTimes) {
    final raw = <int, List<({String id, String? list, FocusTimeRange range})>>{
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) day: [],
    };
    for (final time in focusTimes) {
      for (final range in time.ranges) {
        for (final weekday in range.weekdays) {
          raw[weekday]!.add((
            id: time.id,
            list: time.blockListId,
            range: range,
          ));
        }
      }
    }

    var hasEntries = false;
    var earliest = FocusTime.minutesPerDay;
    var latest = 0;
    final days = <int, List<FocusWeekEntry>>{};
    for (final MapEntry(key: weekday, value: entries) in raw.entries) {
      entries.sort((a, b) {
        final byStart = a.range.startMinute.compareTo(b.range.startMinute);
        if (byStart != 0) return byStart;
        final byEnd = a.range.endMinute.compareTo(b.range.endMinute);
        if (byEnd != 0) return byEnd;
        return a.id.compareTo(b.id);
      });
      for (final entry in entries) {
        hasEntries = true;
        if (entry.range.startMinute < earliest) {
          earliest = entry.range.startMinute;
        }
        if (entry.range.endMinute > latest) latest = entry.range.endMinute;
      }
      days[weekday] = _layOut(weekday, entries);
    }

    if (!hasEntries) return FocusWeek._(days, _fallbackFirst, _fallbackLast);
    final firstHour = (earliest ~/ 60 - 1).clamp(0, 24);
    final lastHour = ((latest + 59) ~/ 60 + 1).clamp(0, 24);
    return FocusWeek._(days, firstHour, lastHour);
  }

  /// Office hours, shown while the week is still unplanned.
  static const _fallbackFirst = 8;
  static const _fallbackLast = 18;

  final Map<int, List<FocusWeekEntry>> _days;

  /// First and last full hour the grid has to show; one padded hour around
  /// the entries, clamped to the day, 8–18 for an empty week.
  final int firstHour;
  final int lastHour;

  bool get isEmpty =>
      _days.values.every((entries) => entries.isEmpty);

  /// The day's entries, sorted by start, end, then id. [weekday] is ISO:
  /// Monday = 1 … Sunday = 7, as [DateTime.weekday].
  List<FocusWeekEntry> entriesOn(int weekday) {
    final entries = _days[weekday];
    if (entries == null) {
      throw ArgumentError.value(weekday, 'weekday', 'must be 1–7');
    }
    return entries;
  }

  /// Greedy interval partitioning: within a cluster of transitively
  /// overlapping entries, each one takes the first free column; the cluster's
  /// column count is shared so the calendar divides its width evenly.
  static List<FocusWeekEntry> _layOut(
    int weekday,
    List<({String id, String? list, FocusTimeRange range})> sorted,
  ) {
    final result = <FocusWeekEntry>[];
    var clusterStart = 0;
    var clusterEnd = -1;
    var columnEnds = <int>[];
    var columns = <int>[];

    void finishCluster(int until) {
      for (var i = clusterStart; i < until; i++) {
        final entry = sorted[i];
        result.add(
          FocusWeekEntry(
            weekday: weekday,
            focusTimeId: entry.id,
            blockListId: entry.list,
            startMinute: entry.range.startMinute,
            endMinute: entry.range.endMinute,
            column: columns[i - clusterStart],
            columns: columnEnds.length,
          ),
        );
      }
    }

    for (var i = 0; i < sorted.length; i++) {
      final range = sorted[i].range;
      if (range.startMinute >= clusterEnd) {
        finishCluster(i);
        clusterStart = i;
        columnEnds = [];
        columns = [];
      }
      var column = columnEnds.indexWhere((end) => end <= range.startMinute);
      if (column == -1) {
        column = columnEnds.length;
        columnEnds.add(range.endMinute);
      } else {
        columnEnds[column] = range.endMinute;
      }
      columns.add(column);
      if (range.endMinute > clusterEnd) clusterEnd = range.endMinute;
    }
    finishCluster(sorted.length);
    return result;
  }
}


/// Where "now" sits in the planned week, computed once from the injected
/// clock so the calendar can mark today, the current minute and the running
/// range without ever asking for the time itself (#363).
class FocusWeekNow {
  const FocusWeekNow._(this.weekday, this.minuteOfDay);

  factory FocusWeekNow.at(DateTime now) =>
      FocusWeekNow._(now.weekday, now.hour * 60 + now.minute);

  /// ISO weekday of today: Monday = 1 … Sunday = 7.
  final int weekday;

  /// Minutes after local midnight.
  final int minuteOfDay;

  /// Whether [entry] is running right now.
  bool isActive(FocusWeekEntry entry) =>
      entry.weekday == weekday &&
      minuteOfDay >= entry.startMinute &&
      minuteOfDay < entry.endMinute;
}


/// Suggests a new focus time for a long-pressed free slot: that weekday and
/// the pressed full hour, clamped to the day – always at least the minimum
/// length, so the editor opens with something valid (#364).
FocusTimeRange suggestedFocusTimeRange({
  required int weekday,
  required int minuteOfDay,
}) {
  final start = ((minuteOfDay ~/ 60) * 60).clamp(
    0,
    FocusTime.minutesPerDay - 60,
  );
  return FocusTimeRange(
    weekdays: {weekday},
    startMinute: start,
    endMinute: start + 60,
  );
}
