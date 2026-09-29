/// How a focus session ended.
sealed class SessionOutcome {
  const SessionOutcome();
}

/// The planned focus time was reached.
final class SessionCompleted extends SessionOutcome {
  const SessionCompleted();

  @override
  bool operator ==(Object other) => other is SessionCompleted;

  @override
  int get hashCode => (SessionCompleted).hashCode;
}

/// The user deliberately ended the session early.
final class SessionCancelled extends SessionOutcome {
  const SessionCancelled();

  @override
  bool operator ==(Object other) => other is SessionCancelled;

  @override
  int get hashCode => (SessionCancelled).hashCode;
}

/// A break inside a session; [end] is null while the pause is still running.
class SessionPause {
  const SessionPause({required this.start, this.end});

  final DateTime start;
  final DateTime? end;

  /// Paused time up to [until] (open pauses count until then).
  Duration durationUntil(DateTime until) {
    final stop = switch (end) {
      final end? when end.isBefore(until) => end,
      _ => until,
    };
    final length = stop.difference(start);
    return length.isNegative ? Duration.zero : length;
  }

  @override
  bool operator ==(Object other) =>
      other is SessionPause && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// One focus session. The timer never counts ticks: remaining and focused
/// time are always derived from timestamps, so a session survives app kills.
class FocusSession {
  FocusSession({
    required this.start,
    required this.planned,
    this.pauses = const [],
    this.end,
    this.outcome,
  }) {
    if (planned <= Duration.zero) {
      throw ArgumentError.value(planned, 'planned', 'must be positive');
    }
  }

  final DateTime start;
  final Duration planned;
  final List<SessionPause> pauses;
  final DateTime? end;
  final SessionOutcome? outcome;

  bool get isFinished => outcome != null;

  bool get isPaused =>
      !isFinished && pauses.isNotEmpty && pauses.last.end == null;

  /// Time actually spent focusing until [now] (or until the end).
  Duration focusedTime(DateTime now) {
    final active = _activeTime(end ?? now);
    return active > planned ? planned : active;
  }

  /// Focus time still left at [now]; never negative.
  Duration remaining(DateTime now) {
    final left = planned - _activeTime(end ?? now);
    return left.isNegative ? Duration.zero : left;
  }

  FocusSession pause(DateTime now) {
    if (isFinished || isPaused) {
      throw StateError('Only a running session can be paused.');
    }
    return _copyWith(pauses: [...pauses, SessionPause(start: now)]);
  }

  FocusSession resume(DateTime now) {
    if (!isPaused) throw StateError('Only a paused session can be resumed.');
    return _copyWith(pauses: _closedPauses(now));
  }

  FocusSession cancel(DateTime now) {
    if (isFinished) throw StateError('The session has already ended.');
    return _copyWith(
      pauses: _closedPauses(now),
      end: now,
      outcome: const SessionCancelled(),
    );
  }

  /// Ends the session at the moment the planned time was reached.
  FocusSession complete() {
    if (isFinished || isPaused) {
      throw StateError('Only a running session can be completed.');
    }
    final paused = pauses.fold(
      Duration.zero,
      (sum, pause) => sum + pause.durationUntil(pause.end ?? start),
    );
    return _copyWith(
      end: start.add(planned + paused),
      outcome: const SessionCompleted(),
    );
  }

  Duration _activeTime(DateTime until) {
    final paused = pauses.fold(
      Duration.zero,
      (sum, pause) => sum + pause.durationUntil(until),
    );
    final active = until.difference(start) - paused;
    return active.isNegative ? Duration.zero : active;
  }

  List<SessionPause> _closedPauses(DateTime now) => [
    for (final pause in pauses)
      pause.end == null ? SessionPause(start: pause.start, end: now) : pause,
  ];

  FocusSession _copyWith({
    List<SessionPause>? pauses,
    DateTime? end,
    SessionOutcome? outcome,
  }) {
    return FocusSession(
      start: start,
      planned: planned,
      pauses: pauses ?? this.pauses,
      end: end ?? this.end,
      outcome: outcome ?? this.outcome,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FocusSession &&
      other.start == start &&
      other.planned == planned &&
      _listEquals(other.pauses, pauses) &&
      other.end == end &&
      other.outcome == outcome;

  @override
  int get hashCode =>
      Object.hash(start, planned, Object.hashAll(pauses), end, outcome);
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
