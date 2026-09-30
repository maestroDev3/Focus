import 'dart:async';

import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/session_repository.dart';

/// In-memory [SessionRepository] for tests.
class FakeSessionRepository implements SessionRepository {
  FocusSession? active;
  final finished = <FocusSession>[];
  final _changes = StreamController<List<FocusSession>>.broadcast();

  @override
  Future<FocusSession?> loadActive() async => active;

  @override
  Future<void> saveActive(FocusSession? session) async => active = session;

  @override
  Future<void> addFinished(FocusSession session) async {
    finished.add(session);
    _changes.add(List.of(finished));
  }

  @override
  Stream<List<FocusSession>> watchFinished() async* {
    yield List.of(finished);
    yield* _changes.stream;
  }

  @override
  Future<void> replaceFinished(List<FocusSession> sessions) async {
    finished
      ..clear()
      ..addAll(sessions);
    _changes.add(List.of(finished));
  }
}
