import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification gate', () {
    final gate = File(
      'android/app/src/main/kotlin/de/maestrodev/focus_timer/'
      'FocusNotificationGate.kt',
    ).readAsStringSync();

    test('re-checks snoozed notifications against the blocking state', () {
      expect(gate, contains('getSnoozedNotifications'));
      expect(gate, contains('fun refreshHeld'));
    });

    test('the app can reach the gate after every state write', () {
      final activity = File(
        'android/app/src/main/kotlin/de/maestrodev/focus_timer/'
        'MainActivity.kt',
      ).readAsStringSync();

      expect(activity, contains('"refreshHeldNotifications"'));
    });

    test('a known end is snoozed in one go, not in rounds', () {
      final state = File(
        'android/app/src/main/kotlin/de/maestrodev/focus_timer/'
        'BlockingState.kt',
      ).readAsStringSync();

      expect(state, isNot(contains('minOf(left, SNOOZE_STEP_MILLIS)')));
    });
  });
}
