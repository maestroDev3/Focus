import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_timer.dart';

import '../support/fake_session_repository.dart';

void main() {
  final tenOClock = DateTime(2026, 10, 14, 10);
  const planned = Duration(minutes: 25);
  late FakeSessionRepository repository;
  late DateTime now;
  late FocusTimer timer;

  setUp(() {
    repository = FakeSessionRepository();
    now = tenOClock;
    timer = FocusTimer(repository: repository, clock: () => now);
  });

  group('intention', () {
    test('keeps the intention of a session, trimmed', () async {
      final session = await timer.start(planned, intention: '  Chapter 3  ');

      expect(session.intention, 'Chapter 3');
      expect(repository.active?.intention, 'Chapter 3');
    });

    test('treats a blank intention as none', () async {
      final session = await timer.start(planned, intention: '   ');

      expect(session.intention, isNull);
    });

    test('rejects an intention longer than 120 characters', () {
      expect(
        () => FocusSession(
          start: tenOClock,
          planned: planned,
          intention: 'x' * 121,
        ),
        throwsArgumentError,
      );
    });

    test('stays with the session when it finishes', () async {
      await timer.start(planned, intention: 'Chapter 3');
      now = now.add(planned);

      await timer.completeIfDue();

      expect(repository.finished.single.intention, 'Chapter 3');
    });
  });

  group('reflection', () {
    test('has three calm levels', () {
      expect(SessionReflection.values, [
        SessionReflection.heavy,
        SessionReflection.steady,
        SessionReflection.flowing,
      ]);
    });

    test('is stored on the finished session', () async {
      await timer.start(planned, intention: 'Chapter 3');
      now = now.add(planned);
      await timer.completeIfDue();
      final finished = repository.finished.single;

      await timer.reflect(finished, SessionReflection.flowing);

      expect(repository.finished.single.reflection, SessionReflection.flowing);
      expect(repository.finished.single.intention, 'Chapter 3');
    });

    test('only a finished session can be reflected', () {
      final running = FocusSession(start: tenOClock, planned: planned);

      expect(
        () => running.withReflection(SessionReflection.steady),
        throwsStateError,
      );
    });
  });
}
