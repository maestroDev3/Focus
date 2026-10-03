import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_blocking_state_writer.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesBlockingStateWriter', () {
    test('stores the documented JSON shape for the native side', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final end = DateTime.utc(2026, 9, 30, 10, 25);

      await SharedPreferencesBlockingStateWriter(preferences).write(
        BlockingState(
          active: true,
          packageNames: const {'org.telegram.messenger', 'com.a.b'},
          plannedEnd: end,
        ),
      );

      expect(jsonDecode(preferences.getString('blocking.state.v1') ?? ''), {
        'v': 1,
        'active': true,
        'packages': ['com.a.b', 'org.telegram.messenger'],
        'plannedEndMillis': end.millisecondsSinceEpoch,
        'focusTimes': <Object>[],
      });
    });

    test('stores an inactive state without end', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await SharedPreferencesBlockingStateWriter(
        preferences,
      ).write(const BlockingState.inactive());

      expect(jsonDecode(preferences.getString('blocking.state.v1') ?? ''), {
        'v': 1,
        'active': false,
        'packages': <String>[],
        'plannedEndMillis': null,
        'focusTimes': <Object>[],
      });
    });

    test('stores focus times for the native side', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await SharedPreferencesBlockingStateWriter(preferences).write(
        BlockingState(
          active: false,
          packageNames: const {'org.telegram.messenger'},
          focusTimes: [
            FocusTime(
              id: 'focus-time-1',
              weekdays: const {5, 1, 2},
              startMinute: 540,
              endMinute: 720,
            ),
          ],
        ),
      );

      expect(jsonDecode(preferences.getString('blocking.state.v1') ?? ''), {
        'v': 1,
        'active': false,
        'packages': ['org.telegram.messenger'],
        'plannedEndMillis': null,
        'focusTimes': [
          {
            'weekdays': [1, 2, 5],
            'start': 540,
            'end': 720,
          },
        ],
      });
    });
  
    test('stores the apps of a focus time with its own list', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await SharedPreferencesBlockingStateWriter(preferences).write(
        BlockingState(
          active: false,
          packageNames: const {'org.telegram.messenger'},
          focusTimes: [
            FocusTime(
              id: 'focus-time-1',
              weekdays: const {1},
              startMinute: 480,
              endMinute: 600,
              blockListId: 'list-1',
            ),
          ],
          focusTimePackages: const {
            'focus-time-1': {'com.instagram.android', 'com.b.c'},
          },
        ),
      );

      final stored =
          jsonDecode(preferences.getString('blocking.state.v1') ?? '') as Map;
      expect(stored['focusTimes'], [
        {
          'weekdays': [1],
          'start': 480,
          'end': 600,
          'packages': ['com.b.c', 'com.instagram.android'],
        },
      ]);
    });
});
}
