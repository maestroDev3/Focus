import 'focus_session.dart';

/// Single source of stored focus sessions; implementations decide where the
/// data lives, so a backend or sync can be added later.
abstract interface class SessionRepository {
  /// The session that is currently running or paused, if any.
  Future<FocusSession?> loadActive();

  /// Stores [session] as the active one; `null` clears it.
  Future<void> saveActive(FocusSession? session);

  /// Appends a completed or cancelled session to the history.
  Future<void> addFinished(FocusSession session);

  /// Emits all finished sessions now and after every change.
  Stream<List<FocusSession>> watchFinished();
}
