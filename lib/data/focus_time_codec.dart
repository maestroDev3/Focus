import '../domain/focus_time.dart';

/// A focus time as JSON: `{id, ranges: [{weekdays, start, end}], blockList}`.
/// Used by the repository and by backups.
Map<String, Object?> encodeFocusTime(FocusTime time) => {
  'id': time.id,
  'ranges': [
    for (final range in time.ranges)
      {
        'weekdays': range.weekdays.toList()..sort(),
        'start': range.startMinute,
        'end': range.endMinute,
      },
  ],
  'blockList': ?time.blockListId,
};

/// Reads [encodeFocusTime] JSON, and the single range (`weekdays`, `start`,
/// `end`) stored before #247. Throws [FormatException] for anything else.
FocusTime decodeFocusTime(Object? json) {
  FocusTimeRange range(Object? item) => switch (item) {
    {
      'weekdays': final List<Object?> weekdays,
      'start': final int start,
      'end': final int end,
    } =>
      FocusTimeRange(
        weekdays: weekdays.cast<int>().toSet(),
        startMinute: start,
        endMinute: end,
      ),
    _ => throw FormatException('Malformed focus time range: $item'),
  };
  return switch (json) {
    {'id': final String id, 'ranges': final List<Object?> ranges} =>
      FocusTime.withRanges(
        id: id,
        ranges: [for (final item in ranges) range(item)],
        blockListId: json['blockList'] as String?,
      ),
    {'id': final String id} => FocusTime.withRanges(
      id: id,
      ranges: [range(json)],
      // Optional since #144; older focus times have none.
      blockListId: json['blockList'] as String?,
    ),
    _ => throw FormatException('Malformed focus time: $json'),
  };
}
