import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_timer.dart';

import '../support/fake_session_end_alarm.dart';
import '../support/fake_session_repository.dart';

void main() {
  final tenOClock = DateTime(2026, 10, 2, 10);
  const planned = Duration(minutes: 25);
  late FakeSessionRepository repository;
  late FakeSessionEndAlarm alarm;
  late DateTime now;
  late FocusTimer timer;

  void advance(Duration duration) => now = now.add(duration);

  setUp(() {
    repository = FakeSessionRepository();
    alarm = FakeSessionEndAlarm();
    now = tenOClock;
    timer = FocusTimer(
      repository: repository,
      clock: () => now,
      sessionEndAlarm: alarm,
    );
  });

  group('FocusTimer session-end alarm', () {
    test('is scheduled at the planned end when a session starts', () async {
      await timer.start(planned);

      expect(alarm.scheduledAt, tenOClock.add(planned));
    });

    test('is cancelled on pause and moved to the new end on resume', () async {
      await timer.start(planned);
      advance(const Duration(minutes: 5));

      await timer.pause();
      expect(alarm.scheduledAt, isNull);

      advance(const Duration(minutes: 3));
      await timer.resume();
      expect(alarm.scheduledAt, now.add(const Duration(minutes: 20)));
    });

    test('is cancelled when the session is cancelled', () async {
      await timer.start(planned);
      advance(const Duration(minutes: 12));

      await timer.cancel();

      expect(alarm.scheduledAt, isNull);
    });

    test('is cancelled when the session completes', () async {
      await timer.start(planned);
      advance(planned);

      await timer.completeIfDue();

      expect(alarm.scheduledAt, isNull);
    });

    test('is scheduled at the end of a restored running session', () async {
      repository.active = FocusSession(
        start: tenOClock.subtract(const Duration(minutes: 10)),
        planned: planned,
      );

      await timer.restore();

      expect(alarm.scheduledAt, tenOClock.add(const Duration(minutes: 15)));
    });

    test('is not scheduled for a restored paused session', () async {
      repository.active = FocusSession(
        start: tenOClock.subtract(const Duration(minutes: 10)),
        planned: planned,
        pauses: [
          SessionPause(start: tenOClock.subtract(const Duration(minutes: 2))),
        ],
      );

      await timer.restore();

      expect(alarm.scheduledAt, isNull);
    });
  });
}
