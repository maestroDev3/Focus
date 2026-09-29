import '../domain/focus_session.dart';

/// Current storage format of a session.
const sessionFormatVersion = 1;

/// Converts [session] into JSON-compatible data (format version 1).
Map<String, Object?> encodeSession(FocusSession session) => {
  'v': sessionFormatVersion,
  'start': session.start.microsecondsSinceEpoch,
  'plannedSeconds': session.planned.inSeconds,
  'pauses': [
    for (final pause in session.pauses)
      {
        'start': pause.start.microsecondsSinceEpoch,
        'end': pause.end?.microsecondsSinceEpoch,
      },
  ],
  'end': session.end?.microsecondsSinceEpoch,
  'outcome': switch (session.outcome) {
    SessionCompleted() => 'completed',
    SessionCancelled() => 'cancelled',
    null => null,
  },
};

/// Reads a session written by [encodeSession]; throws [FormatException] for
/// unknown versions or malformed data instead of silently dropping it.
FocusSession decodeSession(Map<String, Object?> json) {
  if (json['v'] != sessionFormatVersion) {
    throw FormatException('Unknown session format version: ${json['v']}');
  }
  try {
    return FocusSession(
      start: _time(json['start'] as int),
      planned: Duration(seconds: json['plannedSeconds'] as int),
      pauses: [
        for (final pause in json['pauses'] as List<Object?>)
          if (pause case {'start': final int start, 'end': final int? end})
            SessionPause(
              start: _time(start),
              end: end == null ? null : _time(end),
            )
          else
            throw FormatException('Malformed pause: $pause'),
      ],
      end: switch (json['end']) {
        final int end => _time(end),
        _ => null,
      },
      outcome: switch (json['outcome']) {
        'completed' => const SessionCompleted(),
        'cancelled' => const SessionCancelled(),
        null => null,
        final other => throw FormatException('Unknown outcome: $other'),
      },
    );
  } on TypeError catch (error) {
    throw FormatException('Malformed session: $error');
  }
}

DateTime _time(int microseconds) =>
    DateTime.fromMicrosecondsSinceEpoch(microseconds);
