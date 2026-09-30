import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_timer.dart';

import '../support/fake_session_repository.dart';

void main() {
  final tenOClock = DateTime(2026, 9, 29, 10);
  const planned = Duration(minutes: 25);
  late FakeSessionRepository repository;
  late DateTime now;
  late FocusTimer timer;

  void advance(Duration duration) => now = now.add(duration);

  setUp(() {
    repository = FakeSessionRepository();
    now = tenOClock;
    timer = FocusTimer(repository: repository, clock: () => now);
  });

  group('FocusTimer.start', () {
    test('creates a running session now and saves it as active', () async {
      await timer.start(planned);

      final expected = FocusSession(start: tenOClock, planned: planned);
      expect(timer.current, expected);
      expect(repository.active, expected);
    });

    test('throws a StateError while a session runs', () async {
      await timer.start(planned);

      expect(() => timer.start(planned), throwsStateError);
    });
  });

  group('FocusTimer.pause and resume', () {
    test('update and save the active session', () async {
      await timer.start(planned);
      advance(const Duration(minutes: 5));

      await timer.pause();
      expect(timer.current?.isPaused, isTrue);
      expect(repository.active?.isPaused, isTrue);

      advance(const Duration(minutes: 3));
      await timer.resume();
      expect(timer.current?.isPaused, isFalse);
      expect(
        repository.active?.remaining(now),
        const Duration(minutes: 20),
      );
    });
  });

  group('FocusTimer.cancel', () {
    test('stores the session as cancelled and clears the active one', () async {
      await timer.start(planned);
      advance(const Duration(minutes: 12));

      await timer.cancel();

      expect(timer.current, isNull);
      expect(repository.active, isNull);
      expect(repository.finished.single.outcome, isA<SessionCancelled>());
      expect(repository.finished.single.end, now);
    });
  });

  group('FocusTimer.completeIfDue', () {
    test('does nothing before the end', () async {
      await timer.start(planned);
      advance(const Duration(minutes: 24));

      expect(await timer.completeIfDue(), isFalse);
      expect(timer.current, isNotNull);
      expect(repository.finished, isEmpty);
    });

    test('stores the session as completed at the end', () async {
      await timer.start(planned);
      advance(const Duration(minutes: 26));

      expect(await timer.completeIfDue(), isTrue);
      expect(timer.current, isNull);
      expect(repository.active, isNull);
      expect(repository.finished.single.outcome, isA<SessionCompleted>());
      expect(
        repository.finished.single.end,
        tenOClock.add(const Duration(minutes: 25)),
      );
    });
  });

  group('FocusTimer.changes', () {
    test('emits the new state after every action', () async {
      final emitted = <FocusSession?>[];
      final subscription = timer.changes.listen(emitted.add);
      addTearDown(subscription.cancel);

      await timer.start(planned);
      await timer.pause();
      await timer.resume();
      await timer.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(emitted, hasLength(4));
      expect(emitted[0]?.isPaused, isFalse);
      expect(emitted[1]?.isPaused, isTrue);
      expect(emitted[2]?.isPaused, isFalse);
      expect(emitted[3], isNull);
    });
  });

  group('FocusTimer.completedToday', () {
    test('counts only sessions completed today', () async {
      final yesterday = tenOClock.subtract(const Duration(days: 1));
      repository.finished.addAll([
        FocusSession(start: yesterday, planned: planned).complete(),
        FocusSession(
          start: tenOClock.subtract(const Duration(hours: 2)),
          planned: planned,
        ).complete(),
        FocusSession(
          start: tenOClock.subtract(const Duration(hours: 1)),
          planned: planned,
        ).cancel(tenOClock.subtract(const Duration(minutes: 50))),
      ]);

      expect(await timer.completedToday(), 1);
    });
  });

  group('FocusTimer.start with a label', () {
    test('stores the label on the session', () async {
      await timer.start(planned, labelId: 'study');

      expect(timer.current?.labelId, 'study');
      expect(repository.active?.labelId, 'study');
    });
  });

  group('FocusTimer.focusedToday', () {
    test('sums the focused time of sessions that ended today', () async {
      await timer.start(planned);
      advance(const Duration(minutes: 10));
      await timer.cancel();

      expect(await timer.focusedToday(), const Duration(minutes: 10));
    });
  });

  group('FocusTimer.watchFinished', () {
    test('emits the finished sessions', () async {
      await timer.start(planned);
      await timer.cancel();

      expect(await timer.watchFinished().first, repository.finished);
    });
  });
}
