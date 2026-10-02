import 'dart:async';

import 'blocking.dart';
import 'clock.dart';
import 'daily_goal.dart';
import 'focus_session.dart';
import 'session_end_alarm.dart';
import 'session_repository.dart';

/// Runs one focus session at a time and keeps the repository in sync after
/// every change, so the UI only displays state and never owns logic.
class FocusTimer {
  FocusTimer({
    required this._repository,
    required this._clock,
    this._blocking,
    this._sessionEndAlarm,
  });

  final SessionRepository _repository;
  final Clock _clock;

  /// Keeps the native app blocker informed; optional so tests stay simple.
  final BlockingSync? _blocking;

  /// Notifies the user at the planned end while Focus is closed; optional so
  /// tests stay simple.
  final SessionEndAlarm? _sessionEndAlarm;
  final _changes = StreamController<FocusSession?>.broadcast();
  FocusSession? _current;

  /// The running or paused session, or null when idle.
  FocusSession? get current => _current;

  /// Emits the active session (or null) after every change.
  Stream<FocusSession?> get changes => _changes.stream;

  /// Continues the session stored as active (e.g. after Focus was killed);
  /// completes it if its time is already over. Returns the running session.
  Future<FocusSession?> restore() async {
    final session = await _repository.loadActive();
    if (session == null || session.isFinished) return null;
    _current = session;
    if (await completeIfDue()) return null;
    await _blocking?.update(session);
    await _syncAlarm(session);
    _changes.add(session);
    return session;
  }

  Future<FocusSession> start(Duration planned, {String? labelId}) async {
    if (_current != null) throw StateError('A session is already running.');
    final session = FocusSession(
      start: _clock(),
      planned: planned,
      labelId: labelId,
    );
    await _setActive(session);
    return session;
  }

  Future<void> pause() => _setActive(_requireActive().pause(_clock()));

  Future<void> resume() => _setActive(_requireActive().resume(_clock()));

  Future<void> cancel() => _finish(_requireActive().cancel(_clock()));

  /// Completes the session once its planned time is reached; returns whether
  /// it did.
  Future<bool> completeIfDue() async {
    final session = _current;
    if (session == null || session.isPaused) return false;
    if (session.remaining(_clock()) > Duration.zero) return false;
    await _finish(session.complete());
    return true;
  }

  /// All completed and cancelled sessions, now and after every change.
  Stream<List<FocusSession>> watchFinished() => _repository.watchFinished();

  /// Focus time of all sessions that ended today.
  Future<Duration> focusedToday() async =>
      focusedOn(_clock(), await _repository.watchFinished().first);

  /// Number of sessions completed today; drives the Pomodoro cycle.
  Future<int> completedToday() async {
    final today = dayOf(_clock());
    final finished = await _repository.watchFinished().first;
    return finished
        .where(
          (session) =>
              session.outcome is SessionCompleted &&
              switch (session.end) {
                final end? => dayOf(end) == today,
                null => false,
              },
        )
        .length;
  }

  FocusSession _requireActive() {
    final session = _current;
    if (session == null) throw StateError('No session is running.');
    return session;
  }

  /// Publishes the blocking state again, e.g. after the block list changed.
  Future<void> refreshBlocking() async => _blocking?.update(_current);

  Future<void> _setActive(FocusSession? session) async {
    _current = session;
    await _repository.saveActive(session);
    await _blocking?.update(session);
    await _syncAlarm(session);
    _changes.add(session);
  }

  /// A running session has its end scheduled; paused or no session, none.
  Future<void> _syncAlarm(FocusSession? session) async {
    final alarm = _sessionEndAlarm;
    if (alarm == null) return;
    if (session == null || session.isPaused) {
      await alarm.cancel();
      return;
    }
    final now = _clock();
    await alarm.scheduleAt(now.add(session.remaining(now)));
  }

  Future<void> _finish(FocusSession session) async {
    await _repository.addFinished(session);
    await _setActive(null);
  }
}
