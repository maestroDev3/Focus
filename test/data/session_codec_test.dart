import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/session_codec.dart';
import 'package:focus_timer/domain/focus_session.dart';

import '../support/sample_sessions.dart';

void main() {
  group('session codec', () {
    final samples = {
      'running': runningSample(),
      'paused': pausedSample(),
      'completed': completedSample(),
      'cancelled': cancelledSample(),
    };

    samples.forEach((name, session) {
      test('round-trips a $name session', () {
        expect(decodeSession(encodeSession(session)), session);
      });
    });

    test('rejects an unknown format version', () {
      final json = encodeSession(runningSample())..['v'] = 99;

      expect(() => decodeSession(json), throwsFormatException);
    });

    test('round-trips a session with a label', () {
      final labelled = FocusSession(
        start: sampleStart,
        planned: const Duration(minutes: 25),
        labelId: 'study',
      );

      expect(decodeSession(encodeSession(labelled)), labelled);
    });

    test('loads format version 1 without a label', () {
      final start = sampleStart.microsecondsSinceEpoch;
      final end = sampleStart
          .add(const Duration(minutes: 25))
          .microsecondsSinceEpoch;

      final session = decodeSession({
        'v': 1,
        'start': start,
        'plannedSeconds': 1500,
        'pauses': <Object?>[],
        'end': end,
        'outcome': 'completed',
      });

      expect(session.labelId, isNull);
      expect(session.outcome, isA<SessionCompleted>());
      expect(session.planned, const Duration(minutes: 25));
    });
  });
}
