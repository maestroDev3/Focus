import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/session_codec.dart';

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
  });
}
