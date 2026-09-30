import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_blocking_state_writer.dart';
import 'package:focus_timer/domain/blocking.dart';
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
      });
    });
  });
}
